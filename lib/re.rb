require "re/utility"
require "re/version"
require "re/options"
require "re/graph"
require "re/graph_putter"

module Re
  class << self
    def run(args, input_stream = STDIN, exec_type = Options::ExecType::MODULE)
      begin
        options = Options.new(args)
      rescue ArgumentError => e
        puts e
        exit(1)
      end

      putter = TabGraphPutter.new(options, STDOUT)

      visitor = Graph::Visitor.new(
        options,
        input_stream,
      )


      lobby_nodes = visitor.traverse do |node|
        putter.print_node(node)
      end
    end
  end
end
