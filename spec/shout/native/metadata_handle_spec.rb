# frozen_string_literal: true

module Shout
  RSpec.describe Native::MetadataHandle do
    it "is returned by Native.shout_metadata_new" do
      expect(Native.shout_metadata_new).to be_a(described_class)
    end

    it "raises MallocError when libshout returns NULL" do
      expect { described_class.from_native(FFI::Pointer::NULL, nil) }
        .to raise_error(MallocError, "Unable to allocate shout_metadata_t structure")
    end

    it "frees the Metadata struct pointer" do
      pointer = FFI::Pointer.new(0x1234)
      expect(Native).to receive(:shout_metadata_free).with(pointer)
      described_class.release(pointer)
    end

    describe "libshout metadata functions" do
      let(:meta_pointer) { Native.shout_metadata_new }

      it "adds parameters to metadata" do
        expect(Native.shout_metadata_add(meta_pointer, "song", "Artist - Title")).to be 0
      end

      it "adds multiple parameters to metadata" do
        expect(Native.shout_metadata_add(meta_pointer, "artist", "Artist")).to be 0
        expect(Native.shout_metadata_add(meta_pointer, "title", "Title")).to be 0
      end

      it "delegates shout_set_metadata_utf8" do
        shout_pointer = FFI::Pointer.new(0x1234)
        expect(Native).to receive(:shout_set_metadata_utf8).with(shout_pointer, meta_pointer).and_return(0)
        expect(Native.shout_set_metadata_utf8(shout_pointer, meta_pointer)).to be 0
      end

      it "delegates obsolete shout_set_metadata" do
        shout_pointer = FFI::Pointer.new(0x1234)
        expect(Native).to receive(:shout_set_metadata).with(shout_pointer, meta_pointer).and_return(0)
        expect(Native.shout_set_metadata(shout_pointer, meta_pointer)).to be 0
      end
    end
  end
end
