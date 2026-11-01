# frozen_string_literal: true

module Shout
  RSpec.describe Error do
    it "defines error classes descending from ShoutError" do
      expect(InsaneError.ancestors).to include(ShoutError)
      expect(ConnectionError.ancestors).to include(ShoutError)
      expect(LoginError.ancestors).to include(ShoutError)
      expect(SocketIOError.ancestors).to include(ShoutError)
      expect(MallocError.ancestors).to include(ShoutError)
      expect(MetadataError.ancestors).to include(ShoutError)
      expect(ConnectedError.ancestors).to include(ShoutError)
      expect(UnconnectedError.ancestors).to include(ShoutError)
      expect(UnsupportedError.ancestors).to include(ShoutError)
      expect(BusyError.ancestors).to include(ShoutError)
      expect(NoTLSError.ancestors).to include(ShoutError)
      expect(TLSBadCertError.ancestors).to include(ShoutError)
      expect(RetryError.ancestors).to include(ShoutError)
    end

    it "keeps Shout::SocketError as a deprecated alias of SocketIOError" do
      expect(::Shout.const_get(:SocketError)).to be SocketIOError
      expect(::Shout.const_get(:SocketError)).not_to be ::SocketError
    end

    describe ".check_error" do
      it "does not raise on 0 (success)" do
        expect { described_class.check_error(0) }.not_to raise_error
      end

      it "does not raise on positive return codes" do
        expect { described_class.check_error(100) }.not_to raise_error
      end

      it "raises InsaneError on SHOUTERR_INSANE (-1)" do
        expect { described_class.check_error(-1) }.to raise_error(InsaneError)
      end

      it "raises ConnectionError on SHOUTERR_NOCONNECT (-2)" do
        expect { described_class.check_error(-2) }.to raise_error(ConnectionError)
      end

      it "raises LoginError on SHOUTERR_NOLOGIN (-3)" do
        expect { described_class.check_error(-3) }.to raise_error(LoginError)
      end

      it "raises SocketIOError on SHOUTERR_SOCKET (-4)" do
        expect { described_class.check_error(-4) }.to raise_error(SocketIOError)
      end

      it "raises MallocError on SHOUTERR_MALLOC (-5)" do
        expect { described_class.check_error(-5) }.to raise_error(MallocError)
      end

      it "raises MetadataError on SHOUTERR_METADATA (-6)" do
        expect { described_class.check_error(-6) }.to raise_error(MetadataError)
      end

      it "raises ConnectedError on SHOUTERR_CONNECTED (-7)" do
        expect { described_class.check_error(-7) }.to raise_error(ConnectedError)
      end

      it "raises UnconnectedError on SHOUTERR_UNCONNECTED (-8)" do
        expect { described_class.check_error(-8) }.to raise_error(UnconnectedError)
      end

      it "raises UnsupportedError on SHOUTERR_UNSUPPORTED (-9)" do
        expect { described_class.check_error(-9) }.to raise_error(UnsupportedError)
      end

      it "raises BusyError on SHOUTERR_BUSY (-10)" do
        expect { described_class.check_error(-10) }.to raise_error(BusyError)
      end

      it "raises NoTLSError on SHOUTERR_NOTLS (-11)" do
        expect { described_class.check_error(-11) }.to raise_error(NoTLSError)
      end

      it "raises TLSBadCertError on SHOUTERR_TLSBADCERT (-12)" do
        expect { described_class.check_error(-12) }.to raise_error(TLSBadCertError)
      end

      it "raises RetryError on SHOUTERR_RETRY (-13)" do
        expect { described_class.check_error(-13) }.to raise_error(RetryError)
      end

      it "raises generic ShoutError on unknown negative return codes" do
        expect { described_class.check_error(-99) }.to raise_error(ShoutError)
      end

      it "includes message from shout_get_error when shout pointer provided" do
        shout_ptr = FFI::Pointer.new(0x1234)
        allow(Native).to receive(:shout_get_error).with(shout_ptr).and_return("Cannot connect to server")
        expect do
          described_class.check_error(-2, shout_ptr)
        end.to raise_error(ConnectionError, "Cannot connect to server")
      end

      it "falls back to a generic message when libshout has no error text" do
        shout_ptr = FFI::Pointer.new(0x1234)
        allow(Native).to receive(:shout_get_error).with(shout_ptr).and_return("")
        expect do
          described_class.check_error(-2, shout_ptr)
        end.to raise_error(ConnectionError, "libshout error code -2")
      end

      it "falls back to a generic message when reading the error text fails" do
        shout_ptr = FFI::Pointer.new(0x1234)
        allow(Native).to receive(:shout_get_error).and_raise(ArgumentError)
        expect do
          described_class.check_error(-2, shout_ptr)
        end.to raise_error(ConnectionError, "libshout error code -2")
      end

      it "ignores non-Integer return values" do
        expect { described_class.check_error(nil) }.not_to raise_error
      end
    end
  end
end
