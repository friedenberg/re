require 'spec_helper'

describe Re do
  it 'has a version number' do
    expect(Re::VERSION).not_to be nil
  end

  it 'fails when an invalid command is passed in' do
    expect { Re::run(['banananana']) }.to raise_error(SystemExit)
  end
end
