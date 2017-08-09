require 'spec_helper'

module Re::Graph
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

    describe '#each' do
      context 'without a block' do
        it 'returns an enumerator' do
          actual = Node.new('first').each
          expect(actual).to be_a_kind_of(Enumerator)
        end

        it 'can be used to iterate over a single node' do
          first = Node.new('first')
          actual = first.each.next
          expect(actual).to eq first
        end

        it 'can be used to iterate over a simple tree' do
          first = Node.new('first')
          second = Node.new('second')
          third = Node.new('third')

          first.children << second
          first.children << third

          enum = first.each

          [first, second, third].each do |expected|
            actual = enum.next
            expect(actual).to eq expected
          end
        end

        it 'can be used to iterate over a complex tree' do
          first = Node.new('first')
          second = Node.new('second')
          third = Node.new('third')
          fourth = Node.new('fourth')
          fifth = Node.new('fifth')
          sixth = Node.new('sixth')

          first.children += [second, third, fifth]
          third.children << fourth
          fifth.children << sixth

          enum = first.each

          [first, second, third, fourth, fifth, sixth].each do |expected|
            actual = enum.next
            expect(actual).to eq expected
          end
        end
      end

      context 'with a block' do
        it 'calls the block the right number of times' do
          first = Node.new('first')
          second = Node.new('second')
          third = Node.new('third')
          fourth = Node.new('fourth')
          fifth = Node.new('fifth')
          sixth = Node.new('sixth')

          first.children += [second, third, fifth]
          third.children << fourth
          fifth.children << sixth

          expect {|b| first.each(&b) }.to yield_control.exactly(6).times
        end
      end
    end
  end
end
