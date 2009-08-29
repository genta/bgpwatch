#!/usr/local/bin/ruby
require 'rubygems'
require 'pp'
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
      channel = m[0]
    end

=begin
    # (from Net::IRC::Client)
    # Connect to server and event loop.
    def start
      # reset config
      @server_config = Message::ServerConfig.new
      @socket = TCPSocket.open(@host, @port)
      on_connected
      post PASS, @opts.pass if @opts.pass
      post NICK, @opts.nick
      post USER, @opts.user, "0", "*", @opts.real
      while true
        r = select([@socket], [], [], 1)
        if r.nil? then
          send(:on_idle) if respond_to?(:on_idle)
          next
        elsif @socket.eof? then
          break
        end
        l = @socket.gets
        
        begin
          @log.debug "RECEIVE: #{l.chomp}"
          m = Message.parse(l)
          next if on_message(m) === true
          name = "on_#{(COMMANDS[m.command.upcase] || m.command).downcase}"
          send(name, m) if respond_to?(name)
        rescue Exception => e
          warn e
          warn e.backtrace.join("\r\t")
          raise
        rescue Message::InvalidMessage
          @log.error "MessageParse: " + l.inspect
        end
      end
    rescue IOError
    ensure
      finish
    end
=end
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
        :real => @realname || @nick
      })
      @client.channel = @channel
      @client.msgq = @msgq = Queue.new

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
__END__


class MyNotifier < Notifier::IRCClient
  server 'irc6.ii-okinawa.ne.jp'
  port 6667
  nick 'peerbot'
  realname 'IHA *ihanetbot* genta (http://www.ihanet.info/)'
  channel '#mera'
  charcode Kconv::JIS # Kconv::AUTO, Kconv::UTF8, Kconv::SJIS, etc.
end

notifier = MyNotifier.new
notifier.run

loop do
  notifier.notify("Hello, world! from #{Time.now}")
  sleep(5)
end
