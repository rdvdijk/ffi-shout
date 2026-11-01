# frozen_string_literal: true

module Shout
  module Native
    # An owned shout_t handle, as returned by Native.shout_new. It is released
    # with shout_free when it is garbage collected.
    class Handle < FFI::AutoPointer
      def self.release(ptr)
        Native.shout_free(ptr)
      end

      # Called by FFI to wrap the pointer that shout_new returns.
      def self.from_native(ptr, ctx)
        raise MallocError, "Unable to allocate shout_t structure" if ptr.null?

        super
      end
    end
  end
end
