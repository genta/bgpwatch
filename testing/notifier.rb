#!/usr/local/bin/ruby
require 'rubygems'
require 'pp'
require 'net/telnet'
require 'kconv'

require 'modules'

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
    class Client
      def run
      end
    end

    extend Attributes
    attributes :server, :port, :nick, :realname, :channel, :charcode
    attr :sock

    def initialize
      init_attributes
      meta_def(:charconv_in) do |str|
        Kconv.kconv(str, Kconv::UTF8, @charcode || Kconv::AUTO)
      end
      meta_def(:charconv_out) do |str|
        return str if @charcode.nil?
        Kconv.kconv(str, @charcode, Kconv::UTF8)
      end
      super
    end

    def readable?
      read_fd, write_fd, except_fd = IO.select([@sock], [], [], 0)
      return false if read_fd.nil?
      read_fd.include? @sock
    end

    def writable?
      read_fd, write_fd, except_fd = IO.select([], [@sock], [], 0)
      return false if write_fd.nil?
      write_fd.include? @sock
    end

    def putline(str)
      puts "=> #{str}"
      @sock.puts(charconv_out(str))
    end

    def getline
      charconv_in(@sock.gets)
    end

    # runすると，スレッドが作成され，IRCサーバに接続してクライアントが動き出す
    # (予定)
    def run
      @sock = TCPSocket.new(@server, @port)
      putline "USER %s %s %s :%s" %
        [@nick, Socket.gethostname, @server, @realname || @nick]
      putline "NICK #{@nick}"

      while !@sock.nil?
        if (readable?) then
          puts getline
        else
          sleep(1)
        end
      end
      puts "finished"
    end
  end # Notifier::IRCClient
end # Notifier



if __FILE__ == $0 then

class MyNotifier < Notifier::IRCClient
  server 'irc6.ii-okinawa.ne.jp'
  port 6667
  nick 'ihanetbot'
  realname 'IHA *ihanetbot* genta (http://www.ihanet.info/)'
  channel '#mera'
  charcode Kconv::JIS # Kconv::AUTO, Kconv::UTF8, Kconv::SJIS, etc.
end

MyNotifier.new.run

end
