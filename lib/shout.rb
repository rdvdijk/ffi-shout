# frozen_string_literal: true

require "ffi"
require "shout/version"
require "shout/ffi"
require "shout/error"
require "shout/delegation"
require "shout/configuration"
require "shout/metadata"
require "shout/http_metadata"
require "shout/connection"

# Ruby bindings for libshout, the streaming library for Icecast. The libshout
# C functions are attached as module functions on Shout (see
# Shout::FFI::Functions).
module Shout
  extend ::FFI::Library

  ffi_lib ["shout", "libshout.so.3", "libshout.so"]

  FFI.bind(self)

  # Initialize the shout library
  shout_init

  def self.version
    FFI::Version.new
  end

  def self.new(**, &)
    Connection.new(**, &)
  end
end
