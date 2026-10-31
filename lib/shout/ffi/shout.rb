# frozen_string_literal: true

module Shout
  module FFI
    # An owned shout_t handle. It is released with shout_free when it is
    # garbage collected.
    class Shout < ::FFI::AutoPointer
      def self.release(ptr)
        ::Shout.shout_free(ptr)
      end

      def initialize
        ptr = ::Shout.shout_new
        raise ::Shout::MallocError, "Unable to allocate shout_t structure" if ptr.nil? || ptr.null?

        super(ptr)
      end
    end
  end
end
