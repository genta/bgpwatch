#!/usr/local/bin/ruby
# $Id$

require 'rubygems'
require 'metaid'
require 'pp'

require 'modules'
require 'notifier'
require 'watcher'
require 'storage'
require 'resolver'
require 'peerstatus'


#
# BGPWatcher main class.
#
class BGPWatch
  extend Attributes
  attributes :notifier, :watcher, :storage, :resolver, :pidfile
  include Runnable

  # start watching.
  # returns: never return.
  def run
    daemonize do
      run_attributes

      loop do
        if (result = check()) then
          notify(result)
        end
        sleep 60
      end
    end
  end

  def shutdown
    shutdown_attributes
    begin
      File.unlink @pidfile if !@pidfile.nil? and test(?e, @pidfile)
    rescue SystemCallError => e
    end
    exit! 0
  end

  private

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

  # daemonize process and execute given block.
  def daemonize(foreground = false)
    ['SIGINT', 'SIGTERM', 'SIGHUP'].each do |sig|
      Signal.trap(sig) { shutdown }
    end
    return yield if $DEBUG || foreground
    Process.fork do
      Process.setsid
      Dir.chdir '/' 
      File.open('/dev/null', 'r+') do |fd|
        STDIN.reopen fd
        STDOUT.reopen fd
        STDERR.reopen fd
      end
      File.open(@pidfile, 'w') {|fd| fd.puts Process.pid } if !@pidfile.nil?
      yield
    end 
    exit! 0
  end
end
