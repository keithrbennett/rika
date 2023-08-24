# frozen_string_literal: true

require 'spec_helper'
require 'rika/formatters'

RF = Rika::Formatters

describe RF do
  describe '.get' do
    it 'returns the correct formatter for each option character' do
      expect(RF.get('a')).to eq(RF::AWESOME_PRINT_FORMATTER)
      expect(RF.get('i')).to eq(RF::INSPECT_FORMATTER)
      expect(RF.get('j')).to eq(RF::JSON_FORMATTER)
      expect(RF.get('J')).to eq(RF::PRETTY_JSON_FORMATTER)
      expect(RF.get('t')).to eq(RF::TO_S_FORMATTER)
      expect(RF.get('y')).to eq(RF::YAML_FORMATTER)
    end

    it 'raises an error if the option character is invalid' do
      expect { RF.get('x') }.to raise_error(RuntimeError)
    end
  end
end
