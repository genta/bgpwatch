#!/usr/local/bin/ruby
# $Id$

class PeerStatus < Hash
  Entry = Struct.new('PeerStatus', :ipaddr, :asnum, :status, :since_last_event)

  def push(entry)
    self[entry[:ipaddr]] = entry
    self
  end
  alias :add :push
  alias :<< :push

  def ipaddr(addr)
    @storage.select {|entry| entry[:ipaddr] == addr }
  end

  def asnum(asn)
    @storage.select {|entry| entry[:asnum] == asn }
  end

  def diff(other)
    result = Array.new
    self.each_pair do |ipaddr, entry|
      next unless other.has_key?(ipaddr)
      next unless entry.asnum == other[ipaddr].asnum
      if entry.status != other[ipaddr].status then
        result << entry
      end
    end
    return result
  end

  def dump
    self.each do |ipaddr, entry|
      puts "%-30s %6d %10s %10s" % entry.to_a
    end
  end
end



if __FILE__ == $0 then

peers = PeerStatus.new
others = PeerStatus.new

peers << 
  PeerStatus::Entry.new('fe80::1', 64512, 'Up') <<
  PeerStatus::Entry.new('fe80::2', 64513, 'Up') <<
  PeerStatus::Entry.new('fe80::10:1', 64555, 'Down')
      
others <<
  PeerStatus::Entry.new('fe80::2', 64520, 'Down') <<
  PeerStatus::Entry.new('fe80::3', 64514, 'Up') <<
  PeerStatus::Entry.new('fe80::10:1', 64555, 'Up')

peers.diff(others)

end
