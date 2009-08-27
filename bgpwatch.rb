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

DEBUG = true


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
    msg.each {|message| @notifier.notify(message)}
  end

  # start watching.
  # returns: never return.
  def run
    daemonize
    [@notifier, @watcher].each {|process| process.run}

    loop do
      if (result = check) then
        notify(result)
      end
      sleep 60
    end
  end

  private
  # daemonize myself.
  def daemonize
    puts "(daemonize!)" if DEBUG
  end
end



#
# Real instances to work.
# 

class MyNotifier < Notifier::IRCClient
  server 'irc.reicha.net'
  port 6667
  nick 'ihanetbot'
end

class MyStorage < Storage::FileStorage
  file '/tmp/mystorage.db'
end

class MyWatcher < Watcher::Quagga
  server 'localhost'
  user 'login'
  password 'password'
end

Myresolver = {
  64512 => 'genta',
  64513 => 'genta',
  64514 => 'mmasuda',
  64520 => 'ume',
  64530 => 'nork',
}

class MyWatchManager < Watcher::Manager
  watcher MyWatcher
  storage MyStorage
  resolver Myresolver
end

class MyBGPWatch < BGPWatch
  notifier MyNotifier
  watcher MyWatchManager
end

bgpwatcher = MyBGPWatch.new
pp bgpwatcher.run
