# frozen_string_literal: true

module Shout
  RSpec.describe FFI::Version do
    subject(:version) { described_class.new }

    it "gets the version string" do
      expect(version.string).to be_a(String)
      expect(version.string).to match(/\A\d+\.\d+\.\d+/)
    end

    it "gets major, minor, patch versions" do
      expect(version.major).to be_a(Integer)
      expect(version.minor).to be_a(Integer)
      expect(version.patch).to be_a(Integer)
    end

    it "formats as string" do
      expect(version.to_s).to eql version.string
    end

    it "exposes version via Shout.version" do
      expect(::Shout.version.to_s).to eql version.string
    end
  end
end
