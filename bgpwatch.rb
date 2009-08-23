#!/usr/local/bin/ruby
# $Id$

require 'pp'

# Notifier bridge class
module Notifier
  # IRC Client. Client class of Notifier
  class IRCClient
  end # Notifier::IRCClient
end # Notifier


# connect to Quagga/Zebra vty, and fetch peer status
class PeerWatcher
  def initialize
  end

  def get
  end
end

# BGPWatcher main class. The source of the meta-programming.
class BGPWatchStub
  def initialize
  end

  def run
  end

  def notifier(param)
    param = {:class => IRCClient}.merge(param)
  end

  def watcher(param)
  end
end



# Real instance to work.
class BGPWatch < BGPWatchStub
  notifier :class => IRCClient, 
           :server => 'irc.reicha.net:6667', 
           :nick => 'ihanetbot'
  watcher  :server => 'localhost'
end

pp BGPWatch.new.run
