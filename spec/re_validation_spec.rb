
require 'spec_helper'

describe Re::Validation do
  it 'finds the path for an executable' do
    actual = Re::Validation::which('ruby')

    expect(actual).not_to be_nil
    expect(actual).to be_a_kind_of(String)
  end

  it 'returns nil for invalid executables' do
    actual = Re::Validation::which('Tristique')
    expect(actual).to be_nil
  end

  it 'raises an exception for strings with spaces' do
    expect { Re::Validation.which(' ') }.to raise_error(ArgumentError)
  end

  it 'raises an exception for nil' do
    expect { Re::Validation.which(nil) }.to raise_error(ArgumentError)
  end
end
