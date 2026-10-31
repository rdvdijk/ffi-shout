module Shout
  module FFI

    # ManagedStruct to automatically clean up shout_t when garbage collected.
    class Shout < ::FFI::ManagedStruct
      layout :dummy, :char # Not actually used, but FFI needs a layout

      def initialize
        ptr = ::Shout.shout_new
        raise ::Shout::MallocError, "Unable to allocate shout_t structure" if ptr.nil? || ptr.null?
        super(ptr)
      end

      def self.release(ptr)
        ::Shout.shout_free(ptr)
      end
    end

  end
end
