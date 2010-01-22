#!/usr/local/bin/ruby
# $Id$

# $LOAD_PATH.unshift '/please/specify/path/to/bgpwatch/lib/bgpwatch.rb'
$LOAD_PATH.unshift File.expand_path('./lib', File.dirname($0))
require 'bgpwatch'

class MyNotifier < Notifier::IRCClient
  server 'irc6.ii-okinawa.ne.jp' # irc.reicha.net
  port 6667
  nick 'bgpbot6'
  realname 'IHANet BGP peer status watcher (http://www.ihanet.info/)'
  channel '#ihanet'
  charcode Kconv::JIS # Kconv::AUTO, Kconv::UTF8, Kconv::SJIS, etc.
end

class TwitterNotifier < Notifier::TwitterNotifier
  consumer_key 'your_consumer_key_here'
  consumer_secret 'your_consumer_secret_here'
  access_token 'your_access_token_here'
  access_token_secret 'your_access_token_secret_here'
  hash_tag '#YourHashTag'
end

class MyWatcher < Watcher::VTY::Quagga
  server 'localhost'
  user 'root'
  password 'your_quagga_vty_password_here'
  enable_password 'your_quagga_vty_enable_password_here'
end

class MyStorage < Storage::FileStorage
  file '/tmp/bgpbot.db'
end

class MyResolver < Resolver
  file 'example/ihanet-asnum.txt'
  readonly
end

class MyBGPWatch < BGPWatch
  notifier [MyNotifier, TwitterNotifier]
  watcher MyWatcher
  storage MyStorage
  resolver MyResolver
  pidfile '/tmp/bgpbot.pid'
end

MyBGPWatch.new.run
