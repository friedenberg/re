require 'spec_helper'

module Re
  describe Re::Spawn do
    context '.by_line' do

      subject { Spawn }
      context 'when given an empty command' do
        it 'raises an ArgumentError' do
          expect { subject.by_line('') }.to raise_error(ArgumentError)
        end

        it 'raises an ArgumentError' do
          expect { subject.by_line(nil) }.to raise_error(ArgumentError)
        end
      end

      context 'when given a valid command' do
      end

    end
  end
end
