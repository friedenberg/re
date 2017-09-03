require 'open3'
require 'set'
require 're/spawn'
require 're/log'
require 'pry'

module Re
  module Graph
    class Node
      include Enumerable

      attr_accessor(
        :status,
        :children,
        :arg,
        :error,
        :raw_arg,
        :depth,
        :parent,
        :location,
      )

      def initialize(arg)
        if arg.to_s.empty?
          raise ArgumentError.new("Empty arg for node")
        end

        if arg.respond_to?(:chomp)
          arg = arg.chomp
        end

        @status = Status::UNVISITED
        @children = []
        @arg = arg
        @error = nil
        @raw_arg = arg
        @depth = 0
        @parent = nil
        @location = []

        @children_populated = false
        @child_mutex = Mutex.new
        @children_increased = ConditionVariable.new

        @status_mutex = Mutex.new

        Log.d("made a node: #{arg}")
      end

      def priority_compare(other)
        @location <=> other.location
      end

      def status
        @status_mutex.synchronize { @status }
      end

      def status=(new_status)
        retval = @status_mutex.synchronize { @status = new_status }

        if self.visited?
          @child_mutex.synchronize do
            @children_populated = true
            @children_increased.broadcast
            Re::Log.d("marking node \"#{self.arg}\" as being visited")
          end
        end

        retval
      end

      def add_child(child_node)
        child_node.parent = self
        child_node.depth = depth + 1

        @child_mutex.synchronize do
          previous_child = children.last
          new_location = @location.dup

          if previous_child.nil?
            new_location.push(0)
          else
            new_location.push(previous_child.location.last + 1)
          end
          child_node.location = new_location

          children << child_node
          @children_increased.broadcast
        end

        self
      end

      alias_method :<<, :add_child

      def each(blocking_until_visited: true, &block)
        return enum_for(:each) unless block_given?

        if not blocking_until_visited and not can_enum?
          raise ThreadError, "node incomplete"
        end

        block.call(self)

        child_count = 0
        child_index = 0
        has_children_queued_up = false

        update_counts = Proc.new do
          child_count = children.count
          has_children_queued_up = child_index < child_count
        end

        wait_if_necessary = Proc.new do
          update_counts.call

          if @children_populated
            next has_children_queued_up
          end

          if child_count.zero? or not has_children_queued_up
            Re::Log.d("waiting for child_increased in enum for \"#{self.arg}\"")
            @children_increased.wait @child_mutex
            Re::Log.d("done waiting for child_increased in enum for \"#{self.arg}\"")
          end

          #need to update after the wait because we were outside the lock during
          #that time
          update_counts.call

          has_children_queued_up
        end

        get_next_child = Proc.new do
          should_continue_enum = wait_if_necessary.call

          if should_continue_enum
            child = children.fetch(child_index)
            child_index += 1
            next child
          else
            raise StopIteration.new
          end
        end

        begin
          while child = @child_mutex.synchronize(&get_next_child)
            child.each(blocking_until_visited: blocking_until_visited, &block)
          end
        rescue StopIteration => e
          #binding.pry
        end
      end

      module Status
        UNVISITED             = 0
        VISIT_IN_PROGRESS     = 1
        VISIT_SUCCEEDED       = 2
        VISIT_FAILED          = 3

        TERMINAL_STATES = [
          VISIT_SUCCEEDED,
          VISIT_FAILED,
        ]

        def self.to_s(status)
          constants.find do |c|
            v = const_get(c)
            v == status
          end
        end
      end

      def visited?
        Status::TERMINAL_STATES.include?(self.status)
      end
=begin
      def inspect(indent_level = 0)
        string = <<~EOF
          <
            #{self.class.name}
            arg:    #{arg}
            raw:    #{raw_arg}
            depth:  #{depth}
            parent: #{parent&.arg}
            status: #{Status::to_s(status)}
            children:
              #{children.map {|c| c.inspect(indent_level + 1)}.join}
          >
        EOF

        string.each_line.map do |line|
          "\t" * indent_level + line
        end.join
      rescue => e
        binding.pry
      end
=end

      protected

      def can_enum?
        @children_populated and visited?
      end
    end

    class Visitor
      def initialize(options, input_stream)
        @transform = options.transform
        @utility = options.utility
        @max_depth = options.max_depth

        @replacement_string = options.replacement
        @input_stream = input_stream
        @lobby_nodes = []
        @visited = Set.new

        @visit_queue = PriorityQueue.new {|a,b| b.priority_compare(a)}
        @worker_thread_count = options.worker_thread_count
      end

      def traverse(&block)
        worker_threads = @worker_thread_count.times.map do |i|
          Thread.new do
            begin
              while node = @visit_queue.pop
                Re::Log.d("successfully dequeued new visit node \"#{node.arg}\"")
                Re::Log.d("priority: #{node.location}")
                visit_node(node)
                Re::Log.d("successfully visited node \"#{node.arg}\"")
              end
            rescue StopIteration => e
            end
          end.tap {|t| t[:name] = i.to_s }
        end

        #todo listen for ctrl-c and end gracefully
        location_idx = 0
        while line = @input_stream.gets
          node = Node.new(line)
          node.location = [location_idx]
          Re::Log.d("adding lobby node\"#{node.arg}\"")
          @lobby_nodes << node
          @visit_queue << node
          location_idx += 1
        end

        #this causes the calling thread to wait until traversal is complete
        @lobby_nodes.each do |lobby_node|
          lobby_node.each do |node|
            block.call(node) if block_given?
          end
        end

        @visit_queue.close

        worker_threads.each do |t|
          if t.alive?
            t.join
          end
        end

        @lobby_nodes
      end

      def visit_node(node)
        unless @transform.nil? or node.depth == 0
          transform_command = @transform.command(node.arg, @replacement_string)
          node.arg = Spawn.stdout(transform_command).chomp
        end

        if @max_depth != 0 and node.depth >= @max_depth
          #todo add right status
          node.status = Node::Status::VISIT_FAILED
          return node
        end

        node.status = Node::Status::VISIT_IN_PROGRESS

        command = @utility.command(node.arg, @replacement_string)

        process, stderr = Spawn.by_line(command) do |line|
          child = Node.new(line)

          if child.raw_arg.to_s.empty?
            next
          end

          if @visited.add?(child.raw_arg).nil?
            #todo somehow mark as having a cycle
            next
          end

          Re::Log.d("queueing new child node\"#{child.arg}\" with location #{child.location}")
          node << child
          @visit_queue << child
        end

        if not process.nil? and process.exitstatus == 0
          node.status = Node::Status::VISIT_SUCCEEDED
        else
          node.error = stderr.chomp
          node.status = Node::Status::VISIT_FAILED
        end

        node
      end
    end
  end
end
