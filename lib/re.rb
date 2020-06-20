require "re/utility"
require "re/version"
require "re/options"
require "re/graph"
require "re/graph_putter"
require "re/log"
require "re/priority_queue"

module Re
  class << self
    def run(args, input_stream = STDIN, output_stream = STDOUT, exec_type = Options::ExecType::MODULE)
      start_time = Time.new
      begin
        options = Options.new(args)
      rescue ArgumentError => e
        output_stream.puts e
        exit(1)
      end

      visitor = Graph::Visitor.new(options, input_stream)
      putter = TabGraphPutter.new(options, output_stream)

      lobby_nodes = visitor.traverse do |node|
        putter.print_node(node)
      end

      end_time = Time.new

      puts "duration: #{end_time - start_time}"

      lobby_nodes
    end
  end
end
