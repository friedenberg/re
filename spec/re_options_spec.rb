require 'spec_helper'
require 'shellwords'

module Re
  describe Re::Options do
    it 'has a correct utility with no other options' do
      actual = Re::Options.new(%w'cat')
      expect(actual.utility.name).to eq('cat')
    end

    it 'has a correct multi-part utility with no other options' do
      actual = Re::Options.new(%w"ag -l -G blah")
      expect(actual.utility.command).to eq('ag -l -G blah')
    end

    it 'has a correct multi-part utility a correct transform' do
      actual = Re::Options.new(%w'-t basename ag -l -G blah')
      expect(actual.utility.command).to eq('ag -l -G blah')
      expect(actual.transform.name).to eq('basename')
    end

    it 'has a correct multi-part utility and a correct REPLSTR' do
      actual = Re::Options.new(%w'-I % ag -l')
      expect(actual.utility.command).to eq('ag -l')
      expect(actual.replacement).to eq('%')
    end

    context 'when -d, --depth is passed in' do
      it 'defaults to 0' do
        expect(Options.new(%w'ag -l').max_depth).to eq 0
      end

      it 'matches the number passed in to -d' do
        expect(Options.new(%w'-d 3 ag -l').max_depth).to eq 3
      end

      it 'matches the number passed in to --depth' do
        expect(Options.new(%w'--depth 6 ag -l').max_depth).to eq 6
      end
    end
  end
end
