#!/usr/local/bin/ruby
# Net::IRC::Client#on_idle support
# $Id$

class Net::IRC::Client
  def start
    # reset config
    @server_config = Message::ServerConfig.new
    @socket = TCPSocket.open(@host, @port)
    on_connected
    post PASS, @opts.pass if @opts.pass
    post NICK, @opts.nick
    post USER, @opts.user, "0", "*", @opts.real
    # ---- cut here ----
    while true
      r = select([@socket], [], [@socket], 1)
      if r.nil? then
        send(:on_idle) if respond_to?(:on_idle)
        next
      elsif @socket.eof? then
        break
      end
      l = @socket.gets
      # ---- cut here ----
      
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
end
