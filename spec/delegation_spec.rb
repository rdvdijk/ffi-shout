require 'spec_helper'

module Shout

  class FakeConnection
    extend Delegation

    attr_accessor :shout

    delegate_alias_to_shout :foo => :bar
    delegate_to_shout :baz
  end

  describe Delegation do

    let(:shout_pointer) { double("shout_pointer") }
    subject { FakeConnection.new }

    before do
      subject.shout = shout_pointer
    end

    context "#delegate_alias_to_shout" do
      it "delegates #foo= to Shout" do
        expect(::Shout).to receive(:shout_set_bar).with(shout_pointer, anything)
        subject.foo = double("delegate")
      end

      it "delegates #foo to Shout" do
        expect(::Shout).to receive(:shout_get_bar).with(shout_pointer)
        subject.foo
      end

      it "delegates #foo? to Shout" do
        expect(::Shout).to receive(:shout_get_bar).with(shout_pointer)
        subject.foo?
      end
    end

    context "#delegate_to_shout" do
      it "delegates #baz= to Shout" do
        expect(::Shout).to receive(:shout_set_baz).with(shout_pointer, anything)
        subject.baz = double("delegate")
      end

      it "delegates #baz to Shout" do
        expect(::Shout).to receive(:shout_get_baz).with(shout_pointer)
        subject.baz
      end

      it "delegates #baz? to Shout" do
        expect(::Shout).to receive(:shout_get_baz).with(shout_pointer)
        subject.baz?
      end
    end

    context "type conversion" do
      it "converts the input type" do
        value = double("value")
        expect(Delegation::TypeConvertor).to receive(:convert).with(value)
        allow(::Shout).to receive(:shout_set_baz)
        subject.baz = value
      end

      it "passes on converted value to setter" do
        value = double("value")
        converted_value = double("converted_value")
        allow(Delegation::TypeConvertor).to receive(:convert).and_return(converted_value)
        expect(::Shout).to receive(:shout_set_baz).with(shout_pointer, converted_value)
        subject.baz = value
      end

      it "converts question mark style getters to return booleans" do
        allow(::Shout).to receive(:shout_get_baz).and_return(0)
        expect(Delegation::TypeConvertor).to receive(:convert_return).with(0)
        subject.baz?
      end

      it "converts question mark style getters to false when 0" do
        allow(::Shout).to receive(:shout_get_baz).and_return(0)
        expect(subject.baz?).to be false
      end

      it "converts question mark style getters to true when positive" do
        allow(::Shout).to receive(:shout_get_baz).and_return(1)
        expect(subject.baz?).to be true
      end
    end

  end

  describe Delegation::TypeConvertor do

    subject(:converter) { Delegation::TypeConvertor }

    describe "#convert" do
      it "converts true to 1" do
        expect(converter.convert(true)).to eql 1
      end

      it "converts false to 0" do
        expect(converter.convert(false)).to eql 0
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
        expect(converter.convert(:unknown_symbol)).to eql :unknown_symbol
        expect(converter.convert("some string")).to eql "some string"
        expect(converter.convert(1.2)).to eql 1.2
        expect(converter.convert(8000)).to eql 8000
      end
    end

    describe "#convert_return" do
      it "converts 1 to true" do
        expect(converter.convert_return(1)).to eql true
      end

      it "converts 0 to false" do
        expect(converter.convert_return(0)).to eql false
      end

      it "converts nil to false" do
        expect(converter.convert_return(nil)).to eql false
      end

      it "converts false to false" do
        expect(converter.convert_return(false)).to eql false
      end

      it "returns truthy to true" do
        expect(converter.convert_return(:truthy)).to eql true
        expect(converter.convert_return("truthy")).to eql true
        expect(converter.convert_return(Object)).to eql true
        expect(converter.convert_return(Object.new)).to eql true
        expect(converter.convert_return(4.2)).to eql true
      end
    end

  end

end
