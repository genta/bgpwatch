#!/usr/local/bin/ruby
# $Id$

require 'rubygems'
require 'pp'
require 'metaid'
require 'ruby-debug'

require 'modules'
require 'peerstatus'
require 'notifier'
require 'watcher'
require 'storage'
require 'resolver'


#
# BGPWatcher main class.
#
class BGPWatch
  extend Attributes
  attributes :notifier, :watcher
  include Runnable

  # checker method.
  # returns:
  #   false: There are no warnings
  #   Array: There are errors
  def check
    return @watcher.check
  end

  # output message via notifier.
  # receives: Array of messages.
  # returns: nil
  def notify(msg)
    msg.each {|message| @notifier.notify(message) }
  end

  # start watching.
  # returns: never return.
  def run
    daemonize
    [@notifier, @watcher].each {|process| process.run } # XXX

    loop do
      if (result = check()) then
        notify(result)
      end
      sleep 60
    end
  end

  private
  # daemonize myself.
  def daemonize
    puts "(daemonize!)"
  end
end



#
# Real instances to work.
# 

class MyNotifier < Notifier::IRCClient
  server 'irc6.ii-okinawa.ne.jp'
  port 6667
  nick 'peerbot'
  realname 'IHANet BGP peer status watcher (http://www.ihanet.info/)'
  # channel '#mera'
  channel '#ihanet'
  charcode Kconv::JIS # Kconv::AUTO, Kconv::UTF8, Kconv::SJIS, etc.
end

class MyStorage < Storage::FileStorage
  file '/tmp/mystorage.db'
end

class MyWatcher < Watcher::Quagga
  server 'localhost'
  user 'login'
  password 'password'
  enable_password 'enable'
end

class MyResolver < Resolver
  file '/home/genta/asnum.txt'
end

class MyWatchManager < Watcher::Manager
  watcher MyWatcher
  storage MyStorage
  resolver MyResolver
end

class MyBGPWatch < BGPWatch
  notifier MyNotifier
  watcher MyWatchManager
end

bgpwatcher = MyBGPWatch.new
pp bgpwatcher.run
