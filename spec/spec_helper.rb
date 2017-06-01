$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 're'

module SpecHelper
  def with_graph(root, &block)
    Dir.mktmpdir do |path|
      generated = generate_graph(root)
      write_graph(generated, path)

      Dir.chdir(path) do
        yield generated
      end
    end
  end

  def generate_graph(root)
    unless root.kind_of?(Array)
      node = Re::Graph::Node.new(root)
      node.error = "cat: #{node.arg}: No such file or directory"
      node.status = Re::Graph::Node::Status::VISIT_FAILED
      return node
    end

    node = Re::Graph::Node.new(
      root.first
    )

    if root.last.empty?
      node.status = Re::Graph::Node::Status::VISIT_FAILED
      node.error = "cat: #{node.arg}: No such file or directory"
    else
      node.status = Re::Graph::Node::Status::VISIT_SUCCEEDED

      root.last.each do |child|
        node.children << generate_graph(child)
      end
    end

    node
  end

  def write_graph(root, path)
    root_file = File.join(path, root.arg)
    `touch #{root_file}`

    root.children.each do |n|
      `echo #{n.arg} >> #{root_file}`

      if n.status == Re::Graph::Node::Status::VISIT_SUCCEEDED
        write_graph(n, path)
      end
    end
  end
end
