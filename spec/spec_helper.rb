$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 're'

module SpecHelper
  def with_graph_script(roots, &block)
    Dir.mktmpdir do |path|
      graph = roots.map {|r| generate_graph(r)}
      script = generate_script_for_graph(graph)

      Dir.chdir(path) do
        yield graph, save_script(script)
      end
    end
  end

  def generate_script_for_graph(graph)
    whens = graph.flat_map do |root|
      root.flat_map do |node|
        if node.children.empty?
          []
        else
          ["when \'#{node.arg}\'"] + node.children.map {|c| "puts '#{c.arg}'"}
        end
      end
    end

    <<-SCRIPT
    require "shellwords"

    case ARGV.shelljoin
    #{whens.join("\n")}
    else
      exit(1)
    end
    SCRIPT
  end

  def save_script(script_string)
    script_name = "search.rb"

    File.open(script_name, 'w') do |f|
      f.write(script_string)
    end

    script_name
  end

  def generate_graph(root, depth = 0)
    unless root.kind_of?(Array)
      node = Re::Graph::Node.new(root, depth)
      node.error = ""
      node.status = Re::Graph::Node::Status::VISIT_FAILED
      return node
    end

    node = Re::Graph::Node.new(
      root.first,
      depth
    )

    if root.last.empty?
      node.status = Re::Graph::Node::Status::VISIT_FAILED
      node.error = ""
    else
      node.status = Re::Graph::Node::Status::VISIT_SUCCEEDED

      root.last.each do |child|
        node << generate_graph(child, depth + 1)
      end
    end

    node
  end
end
