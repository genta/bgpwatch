#!/usr/local/bin/ruby
# $Id$

require 'pp'

# Notify BGP status to another network service
class Notifier
end

# IRC Client
class IRCClient
end

# connect to Quagga/Zebra vty, and fetch peer status
class PeerWatcher
  def initialize
  end

  def get
  end
end

# BGPWatcher main class. Source of meta-programming.
class BGPWatchStub
  def initialize
  end

  def run
  end
end



# Real instance to work.
class BGPWatch < BGPWatchStub
end

pp BGPWatch.new.run
