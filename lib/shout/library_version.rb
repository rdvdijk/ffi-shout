# frozen_string_literal: true

module Shout
  # The version of the loaded libshout library (shout_version), as returned
  # by Shout.version.
  class LibraryVersion
    include Comparable

    # The oldest libshout with every function these bindings attach
    # (shout_set_metadata_utf8 was added in 2.4.6).
    MINIMUM = "2.4.6"

    attr_reader :string, :major, :minor, :patch

    # Raises LoadError when the loaded libshout is older than MINIMUM.
    def self.ensure_supported!
      version = new
      return version if version >= Gem::Version.new(MINIMUM)

      raise LoadError, "ffi-shout needs libshout #{MINIMUM} or newer, but found #{version.number}"
    end

    def initialize
      major_ptr = FFI::MemoryPointer.new(:int)
      minor_ptr = FFI::MemoryPointer.new(:int)
      patch_ptr = FFI::MemoryPointer.new(:int)

      @string = Native.shout_version(major_ptr, minor_ptr, patch_ptr)
      @major = major_ptr.read_int
      @minor = minor_ptr.read_int
      @patch = patch_ptr.read_int
    end

    # "major.minor.patch", e.g. "2.4.6".
    def number
      [major, minor, patch].join(".")
    end

    def <=>(other)
      Gem::Version.new(number) <=> Gem::Version.new(other.to_s)
    end

    def to_s
      @string
    end
  end
end
