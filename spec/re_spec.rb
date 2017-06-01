require 'spec_helper'
require 'pry'

describe Re do
  include SpecHelper
  it 'has a version number' do
    expect(Re::VERSION).not_to be nil
  end

  let(:dev_null) {stdin = File.open(File::NULL, 'r')}

  it 'fails when an invalid command is passed in' do
    expect { Re::run(['banananana'], dev_null) }.to raise_error(SystemExit)
  end

  it 'generates a graph from a given command' do
    Dir.chdir(File.expand_path('../files/1', __FILE__)) do |path|
      stdin = StringIO.new
      actual = Re::run(
        [
          'cat',
        ],
        stdin,
      )

      stdin.puts('root')
      stdin.close

      expect(actual.children.count).to eq(3)
      expect(actual.children[0].arg).to eq('ignore')
      expect(actual.children[0].status).to eq(Re::Graph::Node::Status::VISIT_FAILED)

      expect(actual.children[1].arg).to eq('apple')
      expect(actual.children[1].status).to eq(Re::Graph::Node::Status::VISIT_SUCCEEDED)

      expect(actual.children[2].arg).to eq('blue')
      expect(actual.children[2].status).to eq(Re::Graph::Node::Status::VISIT_SUCCEEDED)
    end
  end

  it 'generates a graph with children from a given command' do
    Dir.chdir(File.expand_path('../files/2', __FILE__)) do |path|
      actual = Re::run(
        [
          'cat',
        ],
        dev_null,
      )

      expect(actual.children.count).to eq(3)
      expect(actual.children[0].arg).to eq('ignore')
      expect(actual.children[0].status).to eq(Re::Graph::Node::Status::VISIT_FAILED)

      expect(actual.children[1].arg).to eq('apple')
      expect(actual.children[1].children.count).to eq(1)
      expect(actual.children[1].children[0].arg).to eq('blueberry')
      expect(actual.children[1].status).to eq(Re::Graph::Node::Status::VISIT_SUCCEEDED)

      expect(actual.children[2].arg).to eq('blue')
      expect(actual.children[2].status).to eq(Re::Graph::Node::Status::VISIT_SUCCEEDED)
    end
  end

  it 'does not collapse on circular graphs' do
    #todo add timeout
    Dir.chdir(File.expand_path('../files/3', __FILE__)) do |path|
      actual = Re::run(
        [
          'cat',
        ],
        dev_null,
      )

      expect(actual.children.count).to eq(3)
      expect(actual.children[0].arg).to eq('ignore')
      expect(actual.children[0].status).to eq(Re::Graph::Node::Status::VISIT_FAILED)

      expect(actual.children[1].arg).to eq('apple')
      expect(actual.children[1].children.count).to eq(1)
      expect(actual.children[1].children[0].arg).to eq('blueberry')
      expect(actual.children[1].status).to eq(Re::Graph::Node::Status::VISIT_SUCCEEDED)

      expect(actual.children[2].arg).to eq('blue')
      expect(actual.children[2].status).to eq(Re::Graph::Node::Status::VISIT_SUCCEEDED)
    end
  end

  it 'works with a given graph' do
    with_graph(
        [
          'root',
          [
            [
              'apple',
              [ 'blue', 'green', 'yellow', ],
            ],
            [
              'banana',
              [ 'chocolate', 'vanilla', 'mint', ],
            ],
          ],
        ]
    ) do |expected|
      actual = Re::run(
        [
          'cat',
        ],
        dev_null,
      )

      expect(actual).to eq expected
    end
  end
end
