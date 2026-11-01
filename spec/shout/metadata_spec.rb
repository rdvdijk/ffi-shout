# frozen_string_literal: true

module Shout
  RSpec.describe Metadata do
    subject(:metadata) { described_class.new }

    it "initializes an empty metadata structure" do
      expect(metadata.handle).to be_a(Native::MetadataHandle)
      expect(metadata.to_h).to eql({})
    end

    it "initializes with attributes" do
      meta = described_class.new("song" => "Artist - Title", "genre" => "Electronic")
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

    it "returns to_ptr matching the libshout handle" do
      expect(metadata.to_ptr).to eql metadata.handle.to_ptr
    end

    it "yields each key and value and is Enumerable" do
      meta = described_class.new(song: "Song", genre: "Rock")
      expect { |block| meta.each(&block) }.to yield_successive_args(%w[song Song], %w[genre Rock])
      expect(meta.map { |key, _| key }).to eq %w[song genre]
      expect(meta.each.size).to be 2
    end

    it "returns self from #each with a block" do
      expect(metadata.each { nil }).to be metadata
    end

    it "compares by keys and values" do
      expect(described_class.new(song: "A")).to eq described_class.new("song" => "A")
      expect(described_class.new(song: "A")).not_to eq described_class.new(song: "B")
      expect(described_class.new(song: "A")).not_to eq({ "song" => "A" })
    end

    it "can be used as a Hash key" do
      lookup = { described_class.new(song: "A") => :found }
      expect(lookup[described_class.new(song: "A")]).to be :found
    end

    it "shows its keys and values in #inspect" do
      # Hash#inspect added spaces around => in Ruby 3.4.
      expect(described_class.new(song: "A").inspect).to eql "#<Shout::Metadata #{{ "song" => "A" }.inspect}>"
    end

    it "encodes non-string values to UTF-8 strings" do
      metadata.add(:track, 1)
      expect(metadata["track"]).to eql "1"
    end
  end
end
