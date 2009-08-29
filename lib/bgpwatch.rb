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

$DEBUG = true


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
    daemonize do
      [@notifier, @watcher].each {|process| process.run } # XXX

      loop do
        if (result = check()) then
          notify(result)
        end
        sleep 60
      end
    end
  end

  def shutdown
    [@notifier, @watcher].each {|process| process.shutdown } # XXX
    exit! 0
  end

  private
  # daemonize myself.
  def daemonize(foreground = false)
    ['SIGINT', 'SIGTERM', 'SIGHUP'].each do |sig|
      Signal.trap(sig) { shutdown }
    end
    return yield if $DEBUG || foreground
    Process.fork do
      Process.setsid
      Dir.chdir "/" 
      File.open("/dev/null") {|f|
        STDIN.reopen  f
        STDOUT.reopen f
        STDERR.reopen f
      }   
      yield
    end 
    exit! 0
  end
end



if __FILE__ == $0 then
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

MyBGPWatch.new.run
end
