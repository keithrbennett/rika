# frozen_string_literal: true

module Rika
  # This error class reports the inability to load the Tika jar file.
  class TikaLoadError < RuntimeError
    def initialize(message)
      super(message)
    end
  end
end