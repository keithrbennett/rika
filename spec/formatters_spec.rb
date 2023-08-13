# frozen_string_literal: true

require 'spec_helper'
require 'rika/formatters'

describe Formatters do
  describe '.get' do
    it 'returns the correct formatter for each option character' do
      expect(Formatters.get('a')).to eq(Formatters::AWESOME_PRINT)
      expect(Formatters.get('i')).to eq(Formatters::INSPECT)
      expect(Formatters.get('j')).to eq(Formatters::JSON)
      expect(Formatters.get('J')).to eq(Formatters::PRETTY_JSON)
      expect(Formatters.get('t')).to eq(Formatters::TO_S)
      expect(Formatters.get('y')).to eq(Formatters::YAML)
    end

    it 'raises an error if the option character is invalid' do
      expect { Formatters.get('x') }.to raise_error(RuntimeError)
    end
  end

  describe '.REQUIRED_REQUIRE' do
    it 'is a hash' do
      expect(Formatters::REQUIRED_REQUIRE).to be_a(Hash)
    end

    it 'has the correct keys' do
      expect(Formatters::REQUIRED_REQUIRE.keys.to_set).to eq(%w[a j J y].to_set)
    end
  end
end