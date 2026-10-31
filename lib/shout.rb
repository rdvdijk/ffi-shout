require "ffi"
require "forwardable"
require "shout/version"
require "shout/error"
require "shout/ffi"
require "shout/delegation"
require "shout/configuration"
require "shout/metadata"
require "shout/connection"

module Shout

  extend ::FFI::Library
  ffi_lib ["shout", "libshout.so.3", "libshout.so"]

  include FFI

  # Initialize the shout library
  shout_init

  def self.version
    FFI::Version.new
  end

  def self.new(*args, &block)
    Connection.new(*args, &block)
  end

end
