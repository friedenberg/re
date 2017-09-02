require "monitor"

module Re
  class PriorityQueue
    def initialize(duplicates_allowed: true, &block)
      extend(MonitorMixin)

      block = :<=>.to_proc unless block_given?

      if duplicates_allowed
        @comparison = block
      else
        @comparison = Proc.new do |a, b|
          result = block.call(a, b)
          if result == 1 or result == -1
            result
          else
            #todo proper error message
            raise ArgumentError.new
          end
        end
      end

      @nodes = [nil]

      @open = true
      @cond_var = new_cond
    end

    def empty?
      synchronize { @nodes.count == 1 }
    end

    def peek
      synchronize { @nodes[1] }
    end

    def add(value)
      synchronize do
        if closed?
          raise RuntimeError.new, "attempting to add to a closed queue"
        else
          @nodes << value
          sort_last_node
          @cond_var.signal
        end
      end

      self
    end

    alias_method :<<, :add

    def remove_max(blocking: true)
      max = nil

      synchronize do
        if empty? and not closed?
          @cond_var.wait if blocking
        end

        unless empty?
          max = @nodes[1]

          unless max.nil?
            removed = @nodes.pop

            unless empty?
              @nodes[1] = removed
              sort_first_node
            end
          end
        end
      end

      max
    end

    alias_method :pop, :remove_max

    def clear
      synchronize do
        @nodes = [nil]
        @cond_var.broadcast
      end
    end

    def close
      synchronize do
        @open = false
        @cond_var.broadcast
      end
    end

    def closed?
      synchronize { not @open }
    end

    private

    def swap_nodes(a, b)
      @nodes[a], @nodes[b] = @nodes[b], @nodes[a]
    end

    def sort_last_node
      sort_node_from_bottom(@nodes.count - 1)
    end

    def sort_node_from_bottom(index)
      parent_index = get_parent_index(index)

      if parent_index > 0
        parent_value = @nodes[parent_index]
        comparison_result = @comparison.call(
          @nodes[index],
          @nodes[parent_index],
        )

        if comparison_result == 1
          swap_nodes(index, parent_index)
          sort_node_from_bottom(parent_index)
        end
      end
    end

    def sort_first_node
      sort_node_from_top(1)
    end

    def sort_node_from_top(index)
      sort = Proc.new do |child_index|
        unless child_index.nil?
          comparison = @comparison.call(
            @nodes[index],
            @nodes[child_index],
          )

          if comparison == -1
            swap_nodes(index, child_index)
            sort_node_from_top(child_index)
          end
        end
      end

      left_child_index = get_left_child_index(index)
      right_child_index = get_right_child_index(index)

      if left_child_index.nil?
        sort.call(right_child_index)
        return
      end

      if right_child_index.nil?
        sort.call(left_child_index)
        return
      end

      left_child = @nodes[left_child_index]
      right_child = @nodes[right_child_index]

      comparison = @comparison.call(
        @nodes[left_child_index],
        @nodes[right_child_index],
      )

      sort.call(comparison == 1 ? left_child_index : right_child_index)
    end

    def get_parent_index(index)
      (index / 2).to_i
    end

    def get_left_child_index(index)
      result = index * 2

      if result > @nodes.count - 2
        nil
      else
        result
      end
    end

    def get_right_child_index(index)
      result = (index * 2) + 1

      if result > @nodes.count - 1
        nil
      else
        result
      end
    end
  end
end
