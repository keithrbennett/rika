# frozen_string_literal: true

require 'spec_helper'
require 'rika/formatters'

describe Rika::Formatters do
  describe '.get' do
    let(:rf) { described_class }

    it 'returns the correct formatter for each option character' do
      expect(rf.get('a')).to eq(rf::AWESOME_PRINT_FORMATTER)
      expect(rf.get('i')).to eq(rf::INSPECT_FORMATTER)
      expect(rf.get('j')).to eq(rf::JSON_FORMATTER)
      expect(rf.get('J')).to eq(rf::PRETTY_JSON_FORMATTER)
      expect(rf.get('t')).to eq(rf::TO_S_FORMATTER)
      expect(rf.get('y')).to eq(rf::YAML_FORMATTER)
    end

    it 'raises an error if the option character is invalid' do
      expect { rf.get('x') }.to raise_error(KeyError)
    end
  end
end
