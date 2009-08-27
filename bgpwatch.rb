#!/usr/local/bin/ruby
# $Id$

require 'rubygems'
require 'pp'
require 'metaid'
require 'ruby-debug'

DEBUG = true


#
# Attribute module. The source of the meta-programming.
#
module Attributes
  def attributes(*params)
    return @attributes if params.empty?

    params.each do |attr_name|
      attr_accessor attr_name
      meta_def(attr_name) do |value|
        traversally_new = lambda {|item|
          if item.is_a?(Array) then
            return item.map {|val| traversally_new.call(val)}
          else
            return item.is_a?(Class) ? item.new : item
          end
        }
        value = traversally_new.call(value)

        @attributes ||= {}
        @attributes[attr_name] = value
      end
    end

    class_def(:initialize) do
      init_attributes
    end
    class_def(:init_attributes) do
      self.class.attributes.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end
  end
end

module Runnable
  def run
  end

  def shutdown
  end
end


#
# Notifier bridge module
#
module Notifier
  class BasicNotifier
    include Runnable

    # notify message via the notifier object.
    def notify(msg)
      puts "BasicNotifier says: #{msg}"
    end
  end # Notifier::BasicNotifier

  #
  # IRC Client. Client class of Notifier
  #
  class IRCClient < BasicNotifier
    extend Attributes
    attributes :server, :port, :nick
  end # Notifier::IRCClient
end # Notifier


=begin
module PeerStatus
  Up = Object.new
  Down = Object.new
  attr :asnum_table

  def initialize
    @asnum_table = Hash.new
  end

  # returns: Array of PeerStatus::Entry
  def ipaddr(ipaddr)
    @storage[ipaddr]
  end

  # returns: Array of PeerStatus::Entry
  def asnum(asnum)
    @asnum_table[asnum]
  end

  class Entry < Hash
    @storage[ipaddr] = {:asnum => 64512, :status => PeerStatus::Up}

    # key_attr :ipaddr
    # attr :asnum
    # attr :since_last_event
    # attr :status # PeerStatus::Up / PeerStatus::Down
  end
end

class Event
  attr :event  # PeerStatus::Up / PeerStatus::Down
  attr :conn   # PeerStatus::Entry
end
=end

Struct.new('PeerStatus', :ipaddr, :asnum, :since_last_event, :status)


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
      x = Struct.PeerStatus.new('fe80::nork:1', 64530, '00:00:01', 'Down')
      y = Struct.PeerStatus.new('fe80::ume:1', 64520, '00:00:15', 'Up')
      return [x, y]
    end
  end # Watcher::Quagga

  #
  # Manager class of Watcher.
  #
  class Manager
    extend Attributes
    attributes :watcher, :storage
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
      result = get_peers
    end
  end
end # Watcher


#
# store peer status permernently
#
module Storage
  class BasicStorage < Hash
    include Runnable

    # open: do nothing
    def open
    end

    # close: do nothing
    def close
    end
  end

  class FileStorage < BasicStorage
    extend Attributes
    attributes :file

    # open from file and restore datas.
    def open
      puts "FileStorage: opened."
    end

    # store data into file.
    def flush
      puts "FileStorage: flushed"
    end

    # store data into file, and close.
    def close
      flush
      puts "FileStorage: closed."
    end

    def shutdown
      close
    end
  end
end


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

class MyWatchManager < Watcher::Manager
  watcher MyWatcher
  storage MyStorage
end

class MyBGPWatch < BGPWatch
  notifier MyNotifier
  watcher MyWatchManager
end

bgpwatcher = MyBGPWatch.new
pp bgpwatcher.run
