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
  # daemonize process and execute given block.
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
