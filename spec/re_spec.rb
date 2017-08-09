require 'spec_helper'
require 'pry'

describe Re do
  include SpecHelper
  it 'has a version number' do
    expect(Re::VERSION).not_to be nil
  end

  let(:dev_null) {stdin = File.open(File::NULL, 'r')}
  let(:dev_null_w) {stdin = File.open(File::NULL, 'w')}

  it 'fails when an invalid command is passed in' do
    expect { Re::run(['banananana'], dev_null, dev_null_w) }.to raise_error(SystemExit)
  end

  it 'works with a given graph' do
    with_graph_script(
      [
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
        ],
      ]
    ) do |expected, script|
      stdin = StringIO.new
      expected.each {|e| stdin.puts e.arg}
      stdin.rewind

      actual = Re::run(
        [
          'ruby',
          script,
        ],
        stdin,
        dev_null_w
      )

      stdin.close

      expect(actual).to eq expected
    end
  end
end
