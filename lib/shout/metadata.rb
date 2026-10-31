# frozen_string_literal: true

module Shout
  # Song metadata to send to the server, such as "song" => "Artist - Title".
  class Metadata
    attr_reader :metadata_struct

    def initialize(attributes = {})
      @metadata_struct = FFI::Metadata.new
      @attributes = {}

      attributes.each do |key, value|
        add(key, value)
      end
    end

    def add(name, value)
      key_str = name.to_s.encode("UTF-8")
      val_str = value.to_s.encode("UTF-8")

      ret = ::Shout.shout_metadata_add(@metadata_struct, key_str, val_str)
      Error.check_error(ret)

      @attributes[key_str] = val_str
      self
    end
    alias []= add

    def [](key)
      @attributes[key.to_s]
    end

    def to_ptr
      @metadata_struct.to_ptr
    end

    def to_h
      @attributes.dup
    end
  end
end
