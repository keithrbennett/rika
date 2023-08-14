# frozen_string_literal: true

require 'spec_helper'
require 'rika/formatters'

RF = Rika::Formatters

describe RF do
  describe '.get' do
    it 'returns the correct formatter for each option character' do
      expect(RF.get('a')).to eq(RF::AWESOME_PRINT)
      expect(RF.get('i')).to eq(RF::INSPECT)
      expect(RF.get('j')).to eq(RF::JSON)
      expect(RF.get('J')).to eq(RF::PRETTY_JSON)
      expect(RF.get('t')).to eq(RF::TO_S)
      expect(RF.get('y')).to eq(RF::YAML)
    end

    it 'raises an error if the option character is invalid' do
      expect { RF.get('x') }.to raise_error(RuntimeError)
    end
  end

  describe '.REQUIRED_REQUIRE' do
    it 'is a hash' do
      expect(RF::REQUIRED_REQUIRE).to be_a(Hash)
    end

    it 'has the correct keys' do
      expect(RF::REQUIRED_REQUIRE.keys).to match_array(%w[a j J y])
    end
  end
end
