#
# store peer status permernently
#
module Storage
  class BasicStorage < Hash
    include Runnable

    # open: do nothing
    def open
    end

    # close: do nothing
    def close
    end

    def current
      a = PeerStatus.new
      a << PeerStatus::Entry.new('fe80::nork:1', 64530, 'Up', '00:00:01')
      a << PeerStatus::Entry.new('fe80::ume:1', 64520, 'Up', '00:00:15')
    end

    def current=(other)
      other
    end
  end

  class FileStorage < BasicStorage
    extend Attributes
    attributes :file

    # open from file and restore datas.
    def open
      puts "FileStorage: opened."
    end

    # store data into file.
    def flush
      puts "FileStorage: flushed"
    end

    # store data into file, and close.
    def close
      flush
      puts "FileStorage: closed."
    end

    def shutdown
      close
    end
  end
end
