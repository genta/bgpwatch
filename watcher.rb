#
# Peer status watcher module
# 
module Watcher
  #
  # connect to Quagga/Zebra vty, and fetch peer status
  #
  class Quagga
    extend Attributes
    attributes :server, :user, :password
    include Runnable

    def execute(cmd)
      return "(my result\n)"
    end

    def get_peers
      a = PeerStatus.new
      a << PeerStatus::Entry.new('fe80::nork:1', 64530, 'Down', '00:00:01')
      a << PeerStatus::Entry.new('fe80::ume:1', 64520, 'Up', '00:00:15')
      return(a)
    end
  end # Watcher::Quagga

  #
  # Manager class of Watcher.
  #
  class Manager
    extend Attributes
    attributes :watcher, :storage, :resolver
    include Runnable

    # get 'show ipv6 bgp' result.
    # returns: Array
    def get_peers
      @watcher.get_peers
    end

    # check events.
    # retruns:
    #   Array of message (If some errors)
    #   nil (If there is no trouble)
    def check
      last = @storage.current
      result = get_peers
      @storage.current = result

      diff = result.diff(last)
      if !diff.empty? then
        return diff.map {|entry|
          nick = @resolver[entry.asnum] 
          if nick then nick = " a.k.a. #{nick}" end
          "Status has been changed: " +
            "#{last[entry.ipaddr].status} -> #{entry.status} " +
            "(#{entry.ipaddr}, AS#{entry.asnum}#{nick})"
        }
      end
      return nil
    end
  end
end # Watcher
