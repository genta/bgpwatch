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
    [@notifier, @watcher].each {|process| process.run} # XXX

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
  enable_password 'enable'
end

=begin
Myresolver = {
  64512 => 'genta',
  64513 => 'genta',
  64514 => 'mmasuda',
  64520 => 'ume',
  64527 => 'yugmix-home',
  64528 => 'kojima',
  64529 => 'nabeken-osaka',
  64530 => 'nork',
}
#### YAML.dump(Myresolver, File::open('/home/genta/asnum.txt', 'w'))
=end
MyResolver = YAML.load_file('/home/genta/asnum.txt')
MyResolver.extend Runnable

=begin
class MyResolver < Resolver
  file '/home/genta/asnum.txt'
end
=end

class MyWatchManager < Watcher::Manager
  watcher MyWatcher
  storage MyStorage
  # resolver Myresolver
  resolver MyResolver
end

class MyBGPWatch < BGPWatch
  notifier MyNotifier
  watcher MyWatchManager
end

bgpwatcher = MyBGPWatch.new
pp bgpwatcher.run
