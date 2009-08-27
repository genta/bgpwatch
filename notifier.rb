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
    extend Attributes
    attributes :server, :port, :nick
  end # Notifier::IRCClient
end # Notifier
