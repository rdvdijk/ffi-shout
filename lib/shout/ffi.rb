# frozen_string_literal: true

require "shout/ffi/enums"
require "shout/ffi/functions"
require "shout/ffi/version"
require "shout/ffi/shout"
require "shout/ffi/metadata"

module Shout
  # Low-level libshout bindings: constants, enums and attached functions.
  module FFI
    # Defines the enums and attaches the libshout functions on +base+. Checks
    # the libshout version first, because attaching a function that an older
    # libshout lacks would fail with an unclear FFI::NotFoundError.
    def self.bind(base)
      Enums.define(base)
      base.attach_function :shout_version, %i[pointer pointer pointer], :string
      Version.ensure_supported!
      Functions.attach(base)
    end
  end
end
