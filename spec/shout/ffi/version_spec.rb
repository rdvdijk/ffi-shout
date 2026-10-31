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

    it "formats major.minor.patch as #number" do
      expect(version.number).to eql [version.major, version.minor, version.patch].join(".")
    end

    it "compares with version strings" do
      expect(version).to be >= described_class::MINIMUM
      expect(version).to be < "999.0.0"
    end

    describe ".ensure_supported!" do
      def fake_version(number)
        major, minor, patch = number.split(".").map(&:to_i)
        allow(::Shout).to receive(:shout_version) do |major_ptr, minor_ptr, patch_ptr|
          major_ptr.write_int(major)
          minor_ptr.write_int(minor)
          patch_ptr.write_int(patch)
          number
        end
      end

      it "returns the version when libshout is new enough" do
        fake_version("2.4.6")
        expect(described_class.ensure_supported!.number).to eql "2.4.6"
      end

      it "raises LoadError when libshout is too old" do
        fake_version("2.4.5")
        expect { described_class.ensure_supported! }
          .to raise_error(LoadError, "ffi-shout needs libshout 2.4.6 or newer, but found 2.4.5")
      end
    end
  end
end
