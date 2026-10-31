# frozen_string_literal: true

module Shout
  module FFI
    # An owned shout_metadata_t handle. It is released with
    # shout_metadata_free when it is garbage collected.
    class Metadata < ::FFI::AutoPointer
      def self.release(ptr)
        ::Shout.shout_metadata_free(ptr)
      end

      def initialize(ptr = nil)
        ptr ||= ::Shout.shout_metadata_new
        raise ::Shout::MallocError, "Unable to allocate shout_metadata_t structure" if ptr.nil? || ptr.null?

        super
      end
    end
  end
end
