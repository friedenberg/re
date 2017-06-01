require 'spec_helper'

describe Re::Graph do
end

describe Re::Graph::Node do
  it 'cannot be initialized with nil arguments' do
    expect { Node.new(nil) }.to raise_error(ArgumentError)
  end

  it 'has the correct defaults' do
    actual = Node.new('test')
    expect(actual.arg).to eq('test')
    expect(actual.status).to eq Node::Status::UNVISITED
    expect(actual.children).to eq []
  end

  it 'has equality' do
    actual1 = Node.new('test1')
    actual2 = Node.new('test2')
    expect(actual1).not_to eq actual2

    actual1 = Node.new('test')
    actual1.status = Node::Status::VISIT_SUCCEEDED
    actual2 = Node.new('test')

    expect(actual1).not_to eq actual2

    actual1 = Node.new('test')
    actual1.children << Node.new('apple')
    actual2 = Node.new('test')

    expect(actual1).not_to eq actual2

    actual1 = Node.new('test')
    actual1.children << Node.new('apple')
    actual2 = Node.new('test')
    actual2.children << Node.new('apple')

    expect(actual1).to eq actual2
  end
end
