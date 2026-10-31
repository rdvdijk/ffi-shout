# frozen_string_literal: true

RSpec.describe Shout do
  it "attaches the libshout functions as module functions" do
    expect(described_class).to respond_to(:shout_open, :shout_set_metadata_utf8)
  end

  it "does not expose the FFI classes as Shout::Shout or Shout::Version" do
    # Module#constants includes constants of included modules (but not Object).
    expect(described_class.constants).not_to include(:Shout, :Version)
  end

  it "can be loaded under the gem's name with require \"ffi-shout\"" do
    require "ffi-shout"
    expect($LOADED_FEATURES).to include(File.expand_path("../lib/ffi-shout.rb", __dir__))
  end

  it "keeps the libshout functions in Shout::FFI::Functions" do
    expect(described_class::FFI::Functions).to respond_to(:attach)
  end
end
