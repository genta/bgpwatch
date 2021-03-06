# $Id$
require 'net/telnet'

#
# Peer status watcher module
# 
module Watcher
  #
  # Basic class of Watcher
  # 
  class BasicWatcher
    include Runnable
    attr_accessor :owner

    # check events.
    # retruns:
    #   Array of message (If some errors)
    #   nil (If there is no trouble)
    def check
      last = storage.current
      result = get_peers
      storage.current = result
      storage.flush

      diff = result.diff(last)
      if !diff.empty? then
        return diff.map {|entry|
          nick = resolver[entry.asnum] 
          if nick then nick = " a.k.a. #{nick}" end
          "Peer status has been changed: " +
            "#{last[entry.ipaddr].status} -> #{entry.status} " +
            "(#{entry.ipaddr}, AS#{entry.asnum}#{nick})"
        }
      end
      return nil
    end

    def get_peers
      raise RuntimeError, "Please override me in subclass of Watcher"
    end

    private
    def storage; @owner.storage; end
    def resolver; @owner.resolver; end
  end # Watcher::BasicWatcher


  class VTY; end
  #
  # connect to Quagga/Zebra vty, and fetch peer status
  #
  class VTY::Quagga < BasicWatcher
    extend Attributes
    attributes :server, :user, :password, :enable_password

    attr :vty

    def get_peers
      vty_out = execute('show ipv6 bgp summary')
      content = ""
      skipped = false
      vty_out.each do |line|
        next if !skipped and /^Neighbor/ !~ line
        break if skipped and /^$/ =~ line
        skipped = true
        content << line
      end
      content.sub!(/^Neighbor.*\n/, '')
      content.gsub!(/^([a-fA-F0-9:.]+)\n/, '\1 ')

      peers = PeerStatus.new
      content.split("\n").each do |line|
        cols = line.split(/\s+/)
        entry = PeerStatus::Entry.new

        entry.ipaddr, entry.asnum, entry.status, entry.since_last_event =
          cols[0], cols[2].to_i, cols[9], cols[8]
        if entry.status =~ /^\d+$/ then
          entry.status = 'Up'
        else
          entry.status = 'Down'
        end

        peers << entry
      end

      return peers
    end

    private
    def execute(cmd)
      @vty = Net::Telnet.new('Host' => @server,
                             'Prompt' => /[#>] \z/n,
                             'Port' => 2605)
      @vty.waitfor(/^Password:/)
      @vty.cmd(@password)
      if (@enable_password) then
        @vty.cmd('String' => 'enable', 'Match' => /^Password:/)
        @vty.cmd(@enable_password)
      end

      @vty.cmd('terminal length 0')

      result = ""
      @vty.cmd(cmd) {|c| result << c }
      result.sub!(/^#{cmd}\n/o, '')

      @vty.cmd('quit')
      @vty.close

      return result
    end
  end # Watcher::VTY::Quagga
end # Watcher
