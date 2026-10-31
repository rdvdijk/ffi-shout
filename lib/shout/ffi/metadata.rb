module Shout
  module FFI

    # ManagedStruct to automatically clean up shout_metadata_t when garbage collected.
    class Metadata < ::FFI::ManagedStruct
      layout :dummy, :char # Not actually used, but FFI needs a layout

      def initialize(ptr = nil)
        ptr ||= ::Shout.shout_metadata_new
        raise ::Shout::MallocError, "Unable to allocate shout_metadata_t structure" if ptr.nil? || ptr.null?
        super(ptr)
      end

      def self.release(ptr)
        ::Shout.shout_metadata_free(ptr)
      end
    end

  end
end
