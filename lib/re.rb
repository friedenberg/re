require "re/utility"
require "re/version"
require "re/options"
require "re/graph"
require "re/graph_putter"

module Re
  class << self
    def run(args, input_stream = STDIN, output_stream = STDOUT, exec_type = Options::ExecType::MODULE)
      begin
        options = Options.new(args)
      rescue ArgumentError => e
        output_stream.puts e
        exit(1)
      end

      putter = TabGraphPutter.new(options, output_stream)

      visitor = Graph::Visitor.new(
        options,
        input_stream,
      )

      lobby_nodes = visitor.traverse

      print_thread = Thread.new do
        lobby_nodes.each do |root_node|
          root_node.each do |node|
            putter.print_node(node)
          end
        end
      end

      print_thread.join

      lobby_nodes
    end
  end
end
