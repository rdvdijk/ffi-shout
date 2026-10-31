# frozen_string_literal: true

module Shout
  # Song metadata to send to the server, such as "song" => "Artist - Title".
  # Keys and values are stored as UTF-8 strings.
  class Metadata
    include Enumerable

    # The libshout shout_metadata_t handle (an FFI::Metadata).
    attr_reader :handle

    # Deprecated name for #handle, from when it was an FFI struct.
    alias metadata_struct handle

    def initialize(attributes = {})
      @handle = FFI::Metadata.new
      @attributes = {}

      attributes.each do |key, value|
        add(key, value)
      end
    end

    def add(name, value)
      key_str = name.to_s.encode("UTF-8")
      val_str = value.to_s.encode("UTF-8")

      Error.check_error(::Shout.shout_metadata_add(@handle, key_str, val_str))

      @attributes[key_str] = val_str
      self
    end
    alias []= add

    def [](key)
      @attributes[key.to_s]
    end

    # Yields each key and value.
    def each(&)
      return enum_for(:each) { @attributes.size } unless block_given?

      @attributes.each(&)
      self
    end

    def to_h
      @attributes.dup
    end

    def to_ptr
      @handle.to_ptr
    end

    def ==(other)
      other.is_a?(Metadata) && to_h == other.to_h
    end
    alias eql? ==

    def hash
      [self.class, @attributes].hash
    end

    def inspect
      "#<#{self.class.name} #{@attributes.inspect}>"
    end
  end
end
