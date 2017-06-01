require 'spec_helper'

module Re
  describe Utility do
    subject do
      Utility.new(command)
    end

    context 'invalid utility' do
      subject do
        Utility
      end

      it 'should raise an ArgumentError' do
        expect {subject.new('banananana')}.to raise_error(ArgumentError)
        expect {subject.new(nil)}.to raise_error(ArgumentError)
        expect {subject.new('')}.to raise_error(ArgumentError)
      end
    end

    context 'valid utility: cat' do
      let(:command) {'cat'}

      it { expect(subject.name).to eq 'cat' }
      it { expect(subject.args).to eq [] }
      it { expect(subject.components).to eq %w'cat' }
    end

    context 'array of strings: ls -a' do
      let(:command) {['ls', '-a', '-r']}

      it { expect(subject.name).to eq 'ls' }
      it { expect(subject.args).to eq %w'-a -r' }
      it { expect(subject.components).to eq %w'ls -a -r' }
    end

    describe '#command' do
      subject do
        Utility.new(command_string).command(arg, repstr)
      end

      let(:command_string) { 'ls -a -l -t -r' }
      let(:arg) { nil }
      let(:repstr) { nil }

      context 'when it has nil arguments' do
        it 'returns the concatenated command' do
          is_expected.to eq command_string
        end
      end

      context 'when it has a valid command' do
        let(:arg) { 'blah' }
        it 'appends the command to the end' do
          is_expected.to eq 'ls -a -l -t -r blah'
        end
      end

      context 'when it has a command and a repstr' do
        let(:command_string) { 'ls -a -l -t -r %' }
        let(:arg) { 'blah' }
        let(:repstr) { '%' }
        it 'substitutes the appropriate string' do
          is_expected.to eq 'ls -a -l -t -r blah'
        end
      end

      context 'when it has a command with args containing the repstr' do
        let(:command_string) { 'echo "require.*_"' }
        let(:arg) { 'blah' }
        let(:repstr) { '_' }
        it 'substitutes the appropriate string' do
          is_expected.to eq 'echo "require.*blah"'
        end
      end

      context 'when it has a command with pipes' do
        let(:command_string) { 'basename -s .rb _ | awk' }
        let(:arg) { 'blah' }
        let(:repstr) { '_' }

        it 'substitutes the appropriate string' do
          is_expected.to eq 'basename -s .rb blah | awk'
        end
      end
    end
  end
end
