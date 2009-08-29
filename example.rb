#!/usr/local/bin/ruby
# $Id$

# $LOAD_PATH.unshift '/please/specify/path/to/bgpwatch/lib/bgpwatch.rb'
$LOAD_PATH.unshift File.expand_path('..', File.dirname($0))
require 'bgpwatch'

class MyNotifier < Notifier::IRCClient
  server 'irc6.ii-okinawa.ne.jp'
  port 6667
  nick 'gentabot6'
  realname 'IHANet BGP peer status watcher (http://www.ihanet.info/)'
  channel '#mera'
  charcode Kconv::JIS # Kconv::AUTO, Kconv::UTF8, Kconv::SJIS, etc.
end

class MyStorage < Storage::FileStorage
  file '/tmp/gentabot-mystorage.db'
end

class MyWatcher < Watcher::Quagga
  server 'localhost'
  user 'root'
  password 'your_quagga_vty_password_here'
  enable_password 'your_quagga_vty_enable_password_here'
end

class MyResolver < Resolver
  file '/home/genta/asnum.txt'
  # readonly
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
