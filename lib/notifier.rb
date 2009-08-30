#!/usr/local/bin/ruby
require 'rubygems'
require 'net/irc'
require 'kconv'

require 'modules'
require 'monkey-patch/net-irc-client'

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

  class IRCClient < BasicNotifier; end

  # 
  # IRC client
  # 
  class IRCClient::Client < Net::IRC::Client
    attr_accessor :channel, :msgq

    def initialize(*args)
      super
      @channel = @opts.channel if !@opts.channel.nil?
      @msgq = @opts.msgq if !@opts.msgq.nil?
    end

    def on_idle
      return if @msgq.empty?
      msg = @msgq.shift
      post NOTICE, @channel, msg
    end

    def on_rpl_welcome(m)
      post JOIN, @channel
    end

    def on_privmsg(m)
      channel, message = m
    end
  end # IRCClient::Client
  
  #
  # IRC Client. Client class of Notifier
  #
  class IRCClient < BasicNotifier
    extend Attributes
    attributes :server, :port, :nick, :realname, :channel, :charcode
    attr_reader :client, :thread, :msgq

    def initialize
      init_attributes
      @client = Client.new(@server, @port, {
        :nick => @nick,
        :user => @nick,
        :real => @realname || @nick,
        :channel => @channel,
        :msgq => @msgq = Queue.new
      })
      # @client.channel = @channel
      # @client.msgq = @msgq = Queue.new

      # <XXX>
      @client.meta_def(:charconv_in) do |str|
        Kconv.kconv(str, Kconv::UTF8, @charcode || Kconv::AUTO)
      end
      @client.meta_def(:charconv_out) do |str|
        return str if @charcode.nil?
        Kconv.kconv(str, @charcode, Kconv::UTF8)
      end
      # </XXX>
      super
    end

    def run
      @thread = Thread.start { @client.start }
    end

    def shutdown
      @thread.kill
    end

    def notify(msg)
      @msgq << msg
    end
  end # Notifier::IRCClient
end # Notifier
