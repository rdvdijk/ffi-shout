# frozen_string_literal: true

module Shout
  RSpec.describe Delegation do
    subject(:delegator) { delegating_class.new }

    # Delegates to real libshout functions, so verified partial doubles work.
    let(:delegating_class) do
      Class.new do
        extend Delegation

        attr_accessor :shout

        delegate_alias_to_shout foo: :mount
        delegate_to_shout :mount
        delegate_to_shout :public, predicate: true
      end
    end
    let(:shout_pointer) { instance_double(FFI::Pointer) }

    before do
      delegator.shout = shout_pointer
    end

    describe "#delegate_alias_to_shout" do
      it "delegates #foo= to Shout" do
        expect(Native).to receive(:shout_set_mount).with(shout_pointer, anything)
        delegator.foo = "delegate"
      end

      it "delegates #foo to Shout" do
        expect(Native).to receive(:shout_get_mount).with(shout_pointer)
        delegator.foo
      end

      it "does not define #foo?" do
        expect(delegator).not_to respond_to(:foo?)
      end
    end

    describe "#delegate_to_shout" do
      it "delegates #public= to Shout" do
        expect(Native).to receive(:shout_set_public).with(shout_pointer, anything)
        delegator.public = "delegate"
      end

      it "delegates #public to Shout" do
        expect(Native).to receive(:shout_get_public).with(shout_pointer)
        delegator.public
      end

      it "does not define a predicate by default" do
        expect(delegator).not_to respond_to(:mount?)
      end

      it "delegates #public? to Shout when predicate: true" do
        expect(Native).to receive(:shout_get_public).with(shout_pointer)
        delegator.public?
      end
    end

    context "type conversion" do
      it "converts the input type" do
        value = "value"
        expect(Delegation::TypeConvertor).to receive(:convert).with(value)
        allow(Native).to receive(:shout_set_public)
        delegator.public = value
      end

      it "passes on converted value to setter" do
        value = "value"
        converted_value = "converted value"
        allow(Delegation::TypeConvertor).to receive(:convert).and_return(converted_value)
        expect(Native).to receive(:shout_set_public).with(shout_pointer, converted_value)
        delegator.public = value
      end

      it "converts question mark style getters to return booleans" do
        allow(Native).to receive(:shout_get_public).and_return(0)
        expect(Delegation::TypeConvertor).to receive(:convert_return).with(0)
        delegator.public?
      end

      it "converts question mark style getters to false when 0" do
        allow(Native).to receive(:shout_get_public).and_return(0)
        expect(delegator.public?).to be false
      end

      it "converts question mark style getters to true when positive" do
        allow(Native).to receive(:shout_get_public).and_return(1)
        expect(delegator.public?).to be true
      end
    end
  end
end
