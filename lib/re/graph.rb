require 'open3'
require 'set'
require 're/spawn'

module Re
  module Graph
    class Node < Struct.new(
      :status,
      :children,
      :arg,
      :error,
      :raw_arg,
      :depth,
    )

      include Enumerable

      def initialize(arg, depth = 0)
        if arg.to_s.empty?
          raise ArgumentError.new("Empty arg for node")
        end

        arg = arg.chomp

        super(
          Status::UNVISITED,
          [],
          arg,
          nil,
          arg,
          depth,
        )

        def add_to_enum(y)
          y << self
          add_children_to_enum(y)
        end

        def add_children_to_enum(y)
          child_enumerator = children.each

          while child = child_enumerator.next
            begin
              y << child.add_to_enum(y)
              child_enumerator.peek
            rescue StopIteration => e
              if status == Status::VISIT_IN_PROGRESS
                'node waiting'
                next
              else
                'node complete'
                break
              end
            end
          end
        end

        def each
          Enumerator.new do |y|
            add_to_enum(y)
          end
        end
      end

      module Status
        UNVISITED             = 0
        VISIT_IN_PROGRESS     = 1
        VISIT_SUCCEEDED       = 2
        VISIT_FAILED          = 3
      end

      def visited?
        [Status::VISIT_SUCCEEDED, Status::VISIT_FAILED].contains?(self.status)
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
      end

      def traverse(&block)
        while line = @input_stream.gets
          node = Node.new(line)
          @lobby_nodes << visit_node(node, &block)
        end
      end

      def visit_node(node, depth = 0, &block)
        unless @transform.nil? or depth == 0
          transform_command = @transform.command(node.arg, @replacement_string)
          node.arg = Spawn.stdout(transform_command).chomp
        end

        if @max_depth != 0 and depth >= @max_depth
          #todo add right status
          node.status = Node::Status::VISIT_FAILED
          block.call(node) unless block.nil?
          return node
        end

        node.status = Node::Status::VISIT_IN_PROGRESS
        block.call(node) unless block.nil?

        command = @utility.command(node.arg, @replacement_string)

        process, stderr = Spawn.by_line(command) do |line|
          child = Node.new(line, depth + 1)

          if child.raw_arg.to_s.empty?
            next
          end

          if @visited.add?(child.raw_arg).nil?
            next
          end

          node.children << visit_node(child, depth + 1, &block)
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
