# frozen_string_literal: true

require "ffi"
require "shout/version"
require "shout/constants"
require "shout/error"
require "shout/native"
require "shout/delegation"
require "shout/configuration"
require "shout/metadata"
require "shout/http_metadata"
require "shout/connection"

# Ruby bindings for libshout, the streaming library for Icecast. Start with
# Shout::Connection; the raw libshout functions live in Shout::Native.
module Shout
  Native.shout_init

  # The version of the loaded libshout library.
  def self.version
    LibraryVersion.new
  end

  def self.new(**, &)
    Connection.new(**, &)
  end
end
