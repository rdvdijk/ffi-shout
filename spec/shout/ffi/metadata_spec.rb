# frozen_string_literal: true

module Shout
  RSpec.describe FFI::Metadata do
    it "initializes Metadata" do
      real_ptr = ::Shout.shout_metadata_new
      expect(::Shout).to receive(:shout_metadata_new).and_return(real_ptr)
      meta = described_class.new
      expect(meta.to_ptr.address).to eql real_ptr.address
    end

    it "frees the Metadata struct pointer" do
      pointer = ::FFI::Pointer.new(0x1234)
      expect(::Shout).to receive(:shout_metadata_free).with(pointer)
      described_class.release(pointer)
    end

    describe "libshout metadata functions" do
      let(:meta_pointer) { ::Shout.shout_metadata_new }

      after do
        ::Shout.shout_metadata_free(meta_pointer)
      end

      it "adds parameters to metadata" do
        expect(::Shout.shout_metadata_add(meta_pointer, "song", "Artist - Title")).to be 0
      end

      it "adds multiple parameters to metadata" do
        expect(::Shout.shout_metadata_add(meta_pointer, "artist", "Artist")).to be 0
        expect(::Shout.shout_metadata_add(meta_pointer, "title", "Title")).to be 0
      end

      it "delegates shout_set_metadata_utf8" do
        shout_pointer = ::FFI::Pointer.new(0x1234)
        expect(::Shout).to receive(:shout_set_metadata_utf8).with(shout_pointer, meta_pointer).and_return(0)
        expect(::Shout.shout_set_metadata_utf8(shout_pointer, meta_pointer)).to be 0
      end

      it "delegates obsolete shout_set_metadata" do
        shout_pointer = ::FFI::Pointer.new(0x1234)
        expect(::Shout).to receive(:shout_set_metadata).with(shout_pointer, meta_pointer).and_return(0)
        expect(::Shout.shout_set_metadata(shout_pointer, meta_pointer)).to be 0
      end
    end
  end
end
