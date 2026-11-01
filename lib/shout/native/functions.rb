# frozen_string_literal: true

module Shout
  # attach_function declarations for every function in shout.h.
  module Native
    typedef :pointer, :shout_t
    typedef :pointer, :shout_metadata_t

    callback :shout_callback_t, %i[pointer int pointer pointer], :int

    # These `attach_function` declarations are in the order of shout.h.
    # Parameters and return values that take SHOUT_TLS_*, SHOUT_FORMAT_*,
    # SHOUT_PROTOCOL_* or SHOUT_BLOCKING_* values use the FFI enums from
    # enums.rb, so they accept and return symbols such as :mp3 or :http.
    # shout_new and shout_metadata_new return a Handle / MetadataHandle,
    # which frees itself when it is garbage collected.

    # ----------------[ Generic ]----------------

    # initializes the shout library. Must be called before anything else
    attach_function :shout_init, [], :void

    # shuts down the shout library, deallocating any global storage. Don't call
    # anything afterwards
    attach_function :shout_shutdown, [], :void

    # returns a static version string.  Non-null parameters will be set to the
    # value of the library major, minor, and patch levels, respectively
    # (shout_version is attached in native.rb, before the version check)

    # Allocates and sets up a new shout_t.  Returns NULL if it can't get enough
    # memory.  The returns shout_t must be disposed of with shout_free.
    attach_function :shout_new, [], Handle

    # Free all memory allocated by a shout_t
    attach_function :shout_free, [:shout_t], :void

    # Returns a statically allocated string describing the last shout error
    # to occur.  Only valid until the next libshout call on this shout_t
    attach_function :shout_get_error, [:shout_t], :string

    # Return the error code (e.g. SHOUTERR_SOCKET) for this shout instance
    attach_function :shout_get_errno, [:shout_t], :int

    # returns SHOUTERR_CONNECTED or SHOUTERR_UNCONNECTED
    attach_function :shout_get_connected, [:shout_t], :int

    # ----------------[ Configuration ]----------------
    # Parameter manipulation functions.  libshout makes copies of all parameters,
    # the caller may free its copies after giving them to libshout.  May return
    # SHOUTERR_MALLOC

    # Connection parameters
    attach_function :shout_set_host, %i[shout_t string], :int
    attach_function :shout_get_host, [:shout_t], :string

    attach_function :shout_set_port, %i[shout_t ushort], :int
    attach_function :shout_get_port, [:shout_t], :ushort

    attach_function :shout_set_agent, %i[shout_t string], :int
    attach_function :shout_get_agent, [:shout_t], :string

    # See SHOUT_TLS_*
    attach_function :shout_set_tls, %i[shout_t shout_tls], :int
    attach_function :shout_get_tls, [:shout_t], :shout_tls

    # Set the directory for CA certs. Default: operating system's default
    attach_function :shout_set_ca_directory, %i[shout_t string], :int
    attach_function :shout_get_ca_directory, [:shout_t], :string

    # Set a CA cert file for checking. If you use a self signed server cert
    # you can pass this cert using this function for verification.
    # Default: operating system's default
    attach_function :shout_set_ca_file, %i[shout_t string], :int
    attach_function :shout_get_ca_file, [:shout_t], :string

    # Set list of allowed ciphers.
    attach_function :shout_set_allowed_ciphers, %i[shout_t string], :int
    attach_function :shout_get_allowed_ciphers, [:shout_t], :string

    # Authentication parameters
    attach_function :shout_set_user, %i[shout_t string], :int
    attach_function :shout_get_user, [:shout_t], :string

    attach_function :shout_set_password, %i[shout_t string], :int
    attach_function :shout_get_password, [:shout_t], :string

    # Set a client certificate for TLS connections.
    attach_function :shout_set_client_certificate, %i[shout_t string], :int
    attach_function :shout_get_client_certificate, [:shout_t], :string

    # Mount parameters
    attach_function :shout_set_mount, %i[shout_t string], :int
    attach_function :shout_get_mount, [:shout_t], :string

    # Other parameters
    # takes a SHOUT_AI_xxxx argument
    attach_function :shout_set_audio_info, %i[shout_t string string], :int
    attach_function :shout_get_audio_info, %i[shout_t string], :string

    # takes a SHOUT_META_xxxx argument
    attach_function :shout_set_meta, %i[shout_t string string], :int
    attach_function :shout_get_meta, %i[shout_t string], :string

    attach_function :shout_set_public, %i[shout_t uint], :int
    attach_function :shout_get_public, [:shout_t], :uint

    # Set the content language.
    attach_function :shout_set_content_language, %i[shout_t string], :int
    attach_function :shout_get_content_language, [:shout_t], :string

    # Set the format of the content to send.
    attach_function :shout_set_content_format, %i[shout_t shout_format uint string], :int
    attach_function :shout_get_content_format, %i[shout_t pointer pointer pointer], :int

    # takes a SHOUT_PROTOCOL_xxxxx argument
    attach_function :shout_set_protocol, %i[shout_t shout_protocol], :int
    attach_function :shout_get_protocol, [:shout_t], :shout_protocol

    # Instructs libshout to use nonblocking I/O. Must be called before shout_open
    attach_function :shout_set_nonblocking, %i[shout_t shout_blocking], :int
    attach_function :shout_get_nonblocking, [:shout_t], :shout_blocking

    # ----------------[ Actions ]----------------
    # Calls that may wait on the network are attached with `blocking: true`
    # so they release Ruby's GVL and don't freeze other threads.

    # Opens a connection to the server.  All parameters must already be set
    attach_function :shout_open, [:shout_t], :int, blocking: true

    # Closes a connection to the server
    attach_function :shout_close, [:shout_t], :int, blocking: true

    # Send data to the server, parsing it for format specific timing info
    attach_function :shout_send, %i[shout_t pointer size_t], :int, blocking: true

    # Send unparsed data to the server.
    # Returns the number of bytes written, or < 0 on error.
    attach_function :shout_send_raw, %i[shout_t pointer size_t], :ssize_t, blocking: true

    # return the number of bytes currently on the write queue (only makes sense in
    # nonblocking mode).
    attach_function :shout_queuelen, [:shout_t], :ssize_t

    # Puts caller to sleep until it is time to send more data to the server
    attach_function :shout_sync, [:shout_t], :void, blocking: true

    # Amount of time in ms caller should wait before sending again
    attach_function :shout_delay, [:shout_t], :int

    # ----------------[ MP3/AAC ONLY ]----------------

    # Sets MP3 metadata. Returns one of SHOUTERR_XXX.
    attach_function :shout_set_metadata_utf8, %i[shout_t shout_metadata_t], :int, blocking: true

    # Allocates a new metadata structure.  Must be freed by shout_metadata_free.
    attach_function :shout_metadata_new, [], MetadataHandle

    # Free resources allocated by shout_metadata_t
    attach_function :shout_metadata_free, [:shout_metadata_t], :void

    # Add a parameter to the metadata structure.
    attach_function :shout_metadata_add, %i[shout_metadata_t string string], :int

    # ----------------[ Advanced ]----------------

    attach_function :shout_control, %i[shout_t int varargs], :int
    attach_function :shout_set_callback, %i[shout_t shout_callback_t pointer], :int

    # ----------------[ Obsolete ]----------------

    attach_function :shout_set_name, %i[shout_t string], :int
    attach_function :shout_get_name, [:shout_t], :string

    attach_function :shout_set_url, %i[shout_t string], :int
    attach_function :shout_get_url, [:shout_t], :string

    attach_function :shout_set_genre, %i[shout_t string], :int
    attach_function :shout_get_genre, [:shout_t], :string

    attach_function :shout_set_description, %i[shout_t string], :int
    attach_function :shout_get_description, [:shout_t], :string

    attach_function :shout_set_format, %i[shout_t shout_format], :int
    attach_function :shout_get_format, [:shout_t], :shout_format

    attach_function :shout_set_dumpfile, %i[shout_t string], :int
    attach_function :shout_get_dumpfile, [:shout_t], :string

    attach_function :shout_set_metadata, %i[shout_t shout_metadata_t], :int, blocking: true
  end
end
