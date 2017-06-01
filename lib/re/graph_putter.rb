
module Re
  class GraphPutter
    attr_accessor :options, :out

    def initialize(options, stream)
      @options = options
      @out = stream
    end

    def print_node(node)
      self.out.puts node.inspect
    end
  end

  class TabGraphPutter < GraphPutter
    def print_node(node)
      node_string = ("\t" * node.depth) +
        if options.raw_output
          node.raw_arg
        else
          node.arg
        end

      if node.arg != node.raw_arg and not node.children.empty?
        node_string += " -> " + node.arg
      end

      if node.status == Graph::Node::Status::VISIT_FAILED and not node.error.to_s.empty?
        node_string += " stderr: "
        node_string += node.error
      end

      self.out.puts node_string
    end
  end
end
