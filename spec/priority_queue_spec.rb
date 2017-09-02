require 'spec_helper'

module Re
  describe PriorityQueue do
    describe '.new' do
      it 'returns an empty queue' do
        expect(subject).to be_a_kind_of PriorityQueue
        expect(subject.empty?).to be true
      end

      it 'has a default <=> comparison' do
        expect(subject.add(1).add(2).remove_max).to eq 2
      end

      it 'accepts a block to be used as an optional comparison' do
        test_class = Struct.new(:value)
        subject = PriorityQueue.new do |a, b|
          a.value <=> b.value
        end

        subject.add(test_class.new(1)).add(test_class.new(2))
        expect(subject.remove_max).to eq test_class.new(2)
      end
    end

    describe '#empty?' do
      it 'returns non-empty for a populated queue' do
        expect(subject.add(1).empty?).to be false
      end
    end

    describe '#add' do
      it 'can be called many times' do
        1..100.times do |i|
          expect(subject.add(i)).to be_a_kind_of PriorityQueue
          expect(subject.empty?).to be false
        end
      end

      it 'raises an exception when the queue is closed' do
        subject.close
        expect { subject.add(1) }.to raise_error RuntimeError
      end

      context 'when duplicates are not allowed' do
        subject { PriorityQueue.new(duplicates_allowed: false) }
        it 'raises an exception when adding duplicates' do
          expect { subject.add(1).add(1) }.to raise_error ArgumentError
        end
      end
    end

    describe '#remove_max' do
      context 'non-blocking' do
        it 'returns nil when the queue is empty' do
          expect(subject.remove_max(blocking: false)).to eq nil
        end

        it 'returns a lower value each time' do
          (1..10).each do |i|
            subject.add(i)
            expect(subject.peek).to eq i
          end

          10.downto(1).each do |i|
            expect(subject.remove_max(blocking: false)).to eq i
          end

          expect(subject.empty?).to be true
        end
      end

      context 'blocking' do
        it 'will block if no value is present' do
          begin
            blocked_thread = Thread.new do
              subject.remove_max
            end
            blocked_thread.join
            #is this morally repugnant?
          rescue Exception => e
            expect(blocked_thread.status).to eq "sleep"
          ensure
            blocked_thread.exit
          end
        end

        it 'will block until a value becomes available' do
          begin
            blocked_thread = Thread.new do
              expect(subject.remove_max).to eq 1
            end
            subject.add(1)
            blocked_thread.join
          rescue Exception => e
            binding.pry
          ensure
            blocked_thread.exit
          end
        end
      end
    end

    describe '#close' do
      it 'can be called on empty queues' do
        subject.close
        expect(subject.closed?).to eq true
      end

      it 'can be called on populated queues' do
        1..100.times {|i| subject.add(i) }
        subject.close
        expect(subject.closed?).to eq true
      end
    end
  end
end
