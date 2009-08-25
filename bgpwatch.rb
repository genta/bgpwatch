#!/usr/local/bin/ruby
# $Id$

require 'pp'
require 'metaid'

# Notifier bridge module
module Notifier
  # IRC Client. Client class of Notifier
  class IRCClient
  end # Notifier::IRCClient
end # Notifier

# Peer status watcher module
module Watcher
  # connect to Quagga/Zebra vty, and fetch peer status
  class Quagga
    def initialize
  end # Watcher::Quagga
end # Watcher

# store peer status permernently
class Storage
  def initialize
  end
end

# BGPWatcher main class. The source of the meta-programming.
class BGPWatch
  def initialize
    @notifier = self.class.notifier
    @watcher = self.class.watcher
  end

  def run
    pp @notifier
    pp @watcher
    'done'
  end

=begin
  # $B%/%i%9$N%$%s%9%?%s%9JQ?t$X$N%"%/%;%5%a%=%C%I(B
  # $B%a%?2=$G$-$=$&$@(B
  def self.notifier(*param)
    return @notifier if param.empty?
    
    # $B%/%i%9$N%$%s%9%?%s%9JQ?t$K!$(Bparam$B$rJ]B8$7$F$*$/!%(B
    # $B$=$3$7$+;H$($J$$$+$i$J!%(B
    @notifier ||= {}
    @notifier = {:class => Notifier::IRCClient}.merge(*param)
  end

  # $B%/%i%9$N%$%s%9%?%s%9JQ?t$X$N%"%/%;%5%a%=%C%I(B
  # $B%a%?2=$G$-$=$&$@(B
  def self.watcher(*param)
    return @watcher if param.empty?

    # $B%/%i%9$N%$%s%9%?%s%9JQ?t$K!$(Bparam$B$rJ]B8$7$F$*$/!%(B
    # $B$=$3$7$+;H$($J$$$+$i$J!%(B
    @watcher ||= {}
    @watcher = {}.merge(*param)
  end
=end

  def self.attributes(*params)
    return @attributes if params.empty?

    params[0].each do |attr_name, default|
      attr_accessor attr_name
      meta_def(attr_name) do
        # To be done
        # self.instance_variable_set(attr_name, default)
      end
    end
  end

  attributes :notifier => {:class => Notifier::IRCClient},
             :watcher => {}
end



# Real instance to work.
class MyNotifier < Notifier::IRCClient
  server 'irc.reicha.net'
  port 6667
  nick 'ihanetbot'
end

class MyStorage < Storage
  file '/tmp/mystorage.db'
end

class MyWatcher < Watcher::Quagga
  server 'localhost'
  storage MyStorage.new
end


class MyBGPWatch < BGPWatch
  notifier MyNotifier.new
  watcher  MyWatcher.new
end

pp MyBGPWatch.new.run
