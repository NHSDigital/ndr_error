module NdrError
  # Mixin to assist with building of UUIDs.
  module UuidBuilder
    # Populate the primary key column. Taking inspiration
    # from MongoDB, hashes time, machine identifier etc
    # so can be used for ordering at a pinch.
    def construct_uuid
      parts = [
        [Time.current.to_i].pack('N'),                # 4 bytes of current time seconds
        Digest::MD5.digest(Socket.gethostname)[0, 7], # 7 bytes of machine identifier
        [Process.pid % 0xFFFF].pack('n'),             # 2 bytes of pid (looping at 2^16)
        [increment_value].pack('N')[1, 3]             # 3 bytes of incrementing counter
      ]

      format pad_parts(parts)
    end

    private

    # Pad out the components as hex:
    def pad_parts(parts)
      parts.join.unpack('C16').map do |piece|
        piece.to_s(16).tap { |hex| hex.prepend('0') if hex.size == 1 }
      end.join
    end

    def format(string)
      string.sub(/(.{8})(.{14})(.{4})(.{6})/) do
        time, machine, pid, counter = Regexp.last_match[1..4]
        "#{time}-#{machine}-0#{pid}-#{counter}"
      end
    end

    @@_lock  = Mutex.new
    @@_index = 0

    # Used in UUID generation.
    def increment_value
      @@_lock.synchronize do
        @@_index = (@@_index + 1) % 0xFFFFFF
      end
    end
  end
end
