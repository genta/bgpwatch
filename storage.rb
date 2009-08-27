#
# store peer status permernently
#
module Storage
  class BasicStorage
    include Runnable
    attr_accessor :current

    # open: do nothing. override needed.
    def open
    end

    # close: do nothing. override needed.
    def close
    end
  end

  class FileStorage < BasicStorage
    extend Attributes
    attributes :file

    # open from file and restore datas.
    def open
      @current = YAML.load_file(@file) rescue PeerStatus.new
    end

    # store data into file.
    def flush
      puts "FileStorage: flushed"
      File.open(@file, 'w') {|fd| YAML.dump(@current, fd) }
    end

    # store data into file, and close.
    def close
      flush
    end

    def run
      open
    end

    def shutdown
      close
    end
  end
end
