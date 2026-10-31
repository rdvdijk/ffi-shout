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

      it "converts protocol symbols" do
        expect(converter.convert(:http)).to eql SHOUT_PROTOCOL_HTTP
        expect(converter.convert(:xaudiocast)).to eql SHOUT_PROTOCOL_XAUDIOCAST
        expect(converter.convert(:icy)).to eql SHOUT_PROTOCOL_ICY
        expect(converter.convert(:roaraudio)).to eql SHOUT_PROTOCOL_ROARAUDIO
      end

      it "converts format symbols" do
        expect(converter.convert(:ogg)).to eql SHOUT_FORMAT_OGG
        expect(converter.convert(:mp3)).to eql SHOUT_FORMAT_MP3
        expect(converter.convert(:webm)).to eql SHOUT_FORMAT_WEBM
        expect(converter.convert(:matroska)).to eql SHOUT_FORMAT_MATROSKA
        expect(converter.convert(:text)).to eql SHOUT_FORMAT_TEXT
      end

      it "converts tls symbols" do
        expect(converter.convert(:disabled)).to eql SHOUT_TLS_DISABLED
        expect(converter.convert(:auto)).to eql SHOUT_TLS_AUTO
        expect(converter.convert(:auto_no_plain)).to eql SHOUT_TLS_AUTO_NO_PLAIN
        expect(converter.convert(:rfc2818)).to eql SHOUT_TLS_RFC2818
        expect(converter.convert(:rfc2817)).to eql SHOUT_TLS_RFC2817
      end

      it "converts blocking symbols" do
        expect(converter.convert(:full)).to eql SHOUT_BLOCKING_FULL
        expect(converter.convert(:none)).to eql SHOUT_BLOCKING_NONE
        expect(converter.convert(:default)).to eql SHOUT_BLOCKING_DEFAULT
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
