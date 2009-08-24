#!/usr/local/bin/ruby
# $Id$

require 'pp'
require 'metaid'

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

  # クラスのインスタンス変数へのアクセサメソッド
  # メタ化できそうだ
  def self.notifier(param)
    return @notifier if param.empty?
    
    # クラスのインスタンス変数に，paramを保存しておく．
    # そこしか使えないからな．
    @notifier ||= {}
    @notifier = {:class => IRCClient}.merge(param)
  end

  # クラスのインスタンス変数へのアクセサメソッド
  # メタ化できそうだ
  def self.watcher(param)
    return @watcher if param.empty?

    # クラスのインスタンス変数に，paramを保存しておく．
    # そこしか使えないからな．
    @watcher ||= {}
    @watcher = {}.merge(param)
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
