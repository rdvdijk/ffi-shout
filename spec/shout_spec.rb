# frozen_string_literal: true

RSpec.describe Shout do
  it "keeps the libshout functions out of the public module" do
    expect(described_class).not_to respond_to(:shout_open)
    expect(described_class.singleton_class).not_to include(FFI::Library)
  end

  it "does not hide Ruby's ::FFI inside module Shout" do
    expect(described_class.const_defined?(:FFI, false)).to be false
  end

  it "can be loaded under the gem's name with require \"ffi-shout\"" do
    require "ffi-shout"
    expect($LOADED_FEATURES).to include(File.expand_path("../lib/ffi-shout.rb", __dir__))
  end
end
