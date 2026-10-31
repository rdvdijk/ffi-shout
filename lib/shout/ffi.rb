require 'shout/ffi/enums'
require 'shout/ffi/functions'
require 'shout/ffi/version'
require 'shout/ffi/shout'
require 'shout/ffi/metadata'

module Shout
  module FFI

    def self.included(base)
      base.class_eval do
        include Enums
        include Functions
      end
    end

  end
end
