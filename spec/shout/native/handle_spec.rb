# frozen_string_literal: true

module Shout
  RSpec.describe Native::Handle do
    it "is returned by Native.shout_new" do
      expect(Native.shout_new).to be_a(described_class)
    end

    it "raises MallocError when libshout returns NULL" do
      expect { described_class.from_native(FFI::Pointer::NULL, nil) }
        .to raise_error(MallocError, "Unable to allocate shout_t structure")
    end

    it "frees the Shout struct pointer" do
      pointer = FFI::Pointer.new(0x1234)
      expect(Native).to receive(:shout_free).with(pointer)
      described_class.release(pointer)
    end
  end
end
