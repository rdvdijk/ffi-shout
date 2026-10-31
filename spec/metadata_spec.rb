require 'spec_helper'

module Shout
  describe Metadata do
    subject(:metadata) { Metadata.new }

    it "initializes an empty metadata structure" do
      expect(metadata.metadata_struct).to be_a(FFI::Metadata)
      expect(metadata.to_h).to eql({})
    end

    it "initializes with attributes" do
      meta = Metadata.new("song" => "Artist - Title", "genre" => "Electronic")
      expect(meta["song"]).to eql "Artist - Title"
      expect(meta["genre"]).to eql "Electronic"
      expect(meta.to_h).to eql("song" => "Artist - Title", "genre" => "Electronic")
    end

    it "adds metadata using #add" do
      metadata.add("artist", "Queen")
      metadata.add("title", "Bohemian Rhapsody")

      expect(metadata["artist"]).to eql "Queen"
      expect(metadata["title"]).to eql "Bohemian Rhapsody"
    end

    it "adds metadata using #[]=" do
      metadata[:song] = "Daft Punk - Around the World"
      expect(metadata["song"]).to eql "Daft Punk - Around the World"
      expect(metadata[:song]).to eql "Daft Punk - Around the World"
    end

    it "returns to_ptr matching the underlying struct" do
      expect(metadata.to_ptr).to eql metadata.metadata_struct.to_ptr
    end

    it "encodes non-string values to UTF-8 strings" do
      metadata.add(:track, 1)
      expect(metadata["track"]).to eql "1"
    end
  end
end
