require 'spec_helper'

include SpecHelper

module Re::Graph
  describe Node do
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

    describe '#each' do
      let(:single_node) do
        generate_graph(
          [
            1,
            [],
          ]
        )
      end

      let(:simple_graph) do
        generate_graph(
          [
            1,
            [
              2,
              3,
            ],
          ]
        )
      end

      let(:complex_graph) do
        generate_graph(
          [
            1,
            [
              2,
              [
                3,
                [
                  4,
                ],
              ],
              [
                5,
                [
                  6,
                ],
              ]
            ]
          ]
        )
      end

      context 'when blocking' do
        context 'without a block' do
          it 'returns an enumerator' do
            actual = single_node.each(blocking_until_visited: true)
            expect(actual).to be_a_kind_of(Enumerator)
          end

          it 'can be used to iterate over a single node' do
            actual = single_node.each(blocking_until_visited: true).next
            expect(actual).to eq single_node
          end

          it 'can be used to iterate over a simple tree' do
            enum = simple_graph.each(blocking_until_visited: true)

            3.times do |i|
              actual = enum.next
              expect(actual.arg).to eq i + 1
            end

            expect { enum.next }.to raise_error(StopIteration)
          end

          it 'can be used to iterate over a complex tree' do
            enum = complex_graph.each(blocking_until_visited: true)

            6.times do |i|
              actual = enum.next
              expect(actual.arg).to eq i + 1
            end

            expect { enum.next }.to raise_error(StopIteration)
          end
        end

        context 'with a block' do
          it 'yields the right values to the block' do
            root = complex_graph

            expect {|b| root.each(blocking_until_visited: true, &b) }.to yield_control.exactly(6).times

            expect do |b|
              root.each(blocking_until_visited: true) do |n|
                b.to_proc.call(n.arg)
              end
            end.to yield_successive_args(*1..6)
          end
        end
      end

      context 'when non-blocking' do
        context 'without a block' do
          it 'returns an enumerator' do
            actual = single_node.each(blocking_until_visited: false)
            expect(actual).to be_a_kind_of(Enumerator)
          end

          it 'can be used to iterate over a single node' do
            actual = single_node.each(blocking_until_visited: false).next
            expect(actual).to eq single_node
          end

          it 'can be used to iterate over a simple tree' do
            enum = simple_graph.each(blocking_until_visited: false)

            3.times do |i|
              actual = enum.next
              expect(actual.arg).to eq i + 1
            end

            expect { enum.next }.to raise_error(StopIteration)
          end

          it 'can be used to iterate over a complex tree' do
            enum = complex_graph.each(blocking_until_visited: false)

            6.times do |i|
              actual = enum.next
              expect(actual.arg).to eq i + 1
            end

            expect { enum.next }.to raise_error(StopIteration)
          end
        end

        #todo add examples for non-blocking exception

        context 'with a block' do
          it 'calls the block the right number of times' do
            root = complex_graph

            expect {|b| root.each(blocking_until_visited: false, &b) }.to yield_control.exactly(6).times
            expect do |b|
              root.each(blocking_until_visited: false) do |n|
                b.to_proc.call(n.arg)
              end
            end.to yield_successive_args(*1..6)
          end
        end
      end
    end
  end

  describe Visitor do
  end
end
