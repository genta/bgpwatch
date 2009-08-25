#!/usr/local/bin/ruby
# $Id$

require 'pp'
require 'metaid'


# source of the meta-programming.
module Attributes
  def attributes(*params)
    return @attributes if params.empty?

    params.each do |attr|
      attr_accessor attr
      meta_def(attr) do |value|
        @attributes ||= {}
        @attributes[attr] = value
      end
    end

    class_def(:initialize) do
      self.class.attributes.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end
  end
end


# Notifier bridge module
module Notifier
  # IRC Client. Client class of Notifier
  class IRCClient
    extend Attributes
    attributes :server, :port, :nick
  end # Notifier::IRCClient
end # Notifier


# Peer status watcher module
module Watcher
  # connect to Quagga/Zebra vty, and fetch peer status
  class Quagga
    extend Attributes
    attributes :server, :storage
  end # Watcher::Quagga
end # Watcher


# store peer status permernently
class Storage
  extend Attributes
  attributes :file
end


# BGPWatcher main class.
class BGPWatch
  extend Attributes

  def run
    pp @notifier
    pp @watcher
    'done'
  end

  attributes :notifier, :watcher
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
