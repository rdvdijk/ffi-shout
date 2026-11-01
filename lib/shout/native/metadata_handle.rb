# frozen_string_literal: true

module Shout
  module Native
    # An owned shout_metadata_t handle, as returned by
    # Native.shout_metadata_new. It is released with shout_metadata_free when
    # it is garbage collected.
    class MetadataHandle < FFI::AutoPointer
      def self.release(ptr)
        Native.shout_metadata_free(ptr)
      end

      # Called by FFI to wrap the pointer that shout_metadata_new returns.
      def self.from_native(ptr, ctx)
        raise MallocError, "Unable to allocate shout_metadata_t structure" if ptr.null?

        super
      end
    end
  end
end
