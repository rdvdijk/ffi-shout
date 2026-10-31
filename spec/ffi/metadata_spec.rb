require 'spec_helper'

module Shout
  describe FFI::Metadata do
    it "initializes Metadata" do
      real_ptr = ::Shout.shout_metadata_new
      expect(::Shout).to receive(:shout_metadata_new).and_return(real_ptr)
      meta = FFI::Metadata.new
      expect(meta.to_ptr.address).to eql real_ptr.address
    end

    it "frees the Metadata struct pointer" do
      pointer = ::FFI::Pointer.new(0x1234)
      expect(::Shout).to receive(:shout_metadata_free).with(pointer)
      FFI::Metadata.release(pointer)
    end
  end

  describe "FFI calls to metadata" do
    before do
      @meta_pointer = ::Shout.shout_metadata_new
    end

    after do
      ::Shout.shout_metadata_free(@meta_pointer)
    end

    it "adds parameters to metadata" do
      expect(::Shout.shout_metadata_add(@meta_pointer, "song", "Artist - Title")).to eql 0
    end

    it "adds multiple parameters to metadata" do
      expect(::Shout.shout_metadata_add(@meta_pointer, "artist", "Artist")).to eql 0
      expect(::Shout.shout_metadata_add(@meta_pointer, "title", "Title")).to eql 0
    end

    it "delegates shout_set_metadata_utf8" do
      shout_pointer = ::FFI::Pointer.new(0x1234)
      expect(::Shout).to receive(:shout_set_metadata_utf8).with(shout_pointer, @meta_pointer).and_return(0)
      expect(::Shout.shout_set_metadata_utf8(shout_pointer, @meta_pointer)).to eql 0
    end

    it "delegates obsolete shout_set_metadata" do
      shout_pointer = ::FFI::Pointer.new(0x1234)
      expect(::Shout).to receive(:shout_set_metadata).with(shout_pointer, @meta_pointer).and_return(0)
      expect(::Shout.shout_set_metadata(shout_pointer, @meta_pointer)).to eql 0
    end
  end
end
