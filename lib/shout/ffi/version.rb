# frozen_string_literal: true

module Shout
  module FFI
    # The version of the loaded libshout library (shout_version).
    class Version
      attr_reader :string, :major, :minor, :patch

      def initialize
        major_ptr = ::FFI::MemoryPointer.new(:int)
        minor_ptr = ::FFI::MemoryPointer.new(:int)
        patch_ptr = ::FFI::MemoryPointer.new(:int)

        @string = ::Shout.shout_version(major_ptr, minor_ptr, patch_ptr)
        @major = major_ptr.read_int
        @minor = minor_ptr.read_int
        @patch = patch_ptr.read_int
      end

      def to_s
        @string
      end
    end
  end
end
