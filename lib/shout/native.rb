# frozen_string_literal: true

require "shout/constants"
require "shout/library_version"

module Shout
  # The libshout bindings: an FFI::Library with every function in shout.h.
  module Native
    extend FFI::Library

    ffi_lib ["shout", "libshout.so.3", "libshout.so"]

    # Attached first, so the version check below can run before the other
    # functions: attaching a function that an older libshout lacks would fail
    # with an unclear FFI::NotFoundError.
    attach_function :shout_version, %i[pointer pointer pointer], :string
    LibraryVersion.ensure_supported!
  end
end

require "shout/native/enums"
require "shout/native/handle"
require "shout/native/metadata_handle"
require "shout/native/functions"
