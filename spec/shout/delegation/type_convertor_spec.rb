# frozen_string_literal: true

module Shout
  RSpec.describe Delegation::TypeConvertor do
    subject(:converter) { described_class }

    describe "#convert" do
      it "converts true to 1" do
        expect(converter.convert(true)).to be 1
      end

      it "converts false to 0" do
        expect(converter.convert(false)).to be 0
      end

      it "maps :vorbis to :ogg, which libshout treats as the same format" do
        expect(converter.convert(:vorbis)).to be :ogg
      end

      it "leaves other symbols for the FFI enums to convert" do
        expect(converter.convert(:mp3)).to be :mp3
        expect(converter.convert(:http)).to be :http
      end

      it "does not convert other values" do
        expect(converter.convert(:unknown_symbol)).to be :unknown_symbol
        expect(converter.convert("some string")).to eql "some string"
        expect(converter.convert(1.2)).to be 1.2
        expect(converter.convert(8000)).to be 8000
      end
    end

    describe "#convert_return" do
      it "converts 1 to true" do
        expect(converter.convert_return(1)).to be true
      end

      it "converts 0 to false" do
        expect(converter.convert_return(0)).to be false
      end

      it "converts nil to false" do
        expect(converter.convert_return(nil)).to be false
      end

      it "converts false to false" do
        expect(converter.convert_return(false)).to be false
      end

      it "returns truthy to true" do
        expect(converter.convert_return(:truthy)).to be true
        expect(converter.convert_return("truthy")).to be true
        expect(converter.convert_return(Object)).to be true
        expect(converter.convert_return(Object.new)).to be true
        expect(converter.convert_return(4.2)).to be true
      end
    end
  end
end
