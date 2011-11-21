require 'restclient'


#
# We use resque to send messages to loggly
#

class LogglyResque

  @queue = :loggly

  def self.perform(klass,message, time=nil)
    klass.camelize.constantize.send(:send_to_loggly, message, time)
  end
end

#
# THIS CLASS AS AN ABSTRACT BASE CLASS TO SEND EVENTS TO LOGGLY.COM
# events on this content are anything that happends in the app. Not an event were people to to have fun
#
class Loggly

  #
  # THIS IS THE ENDPOINT URL FOR LOGGLY
  #
  @@endpoint = 'http://logs.loggly.com/inputs/'

  #
  # Contructing a full URL. It has the endpoint + the token we generate at:
  # https://venuedriver.loggly.com/inputs
  #
  def self.url
    @@endpoint + self.token
  end

  def self.token
    # Add the token in the subclasses.
    # This method must return a string
    # The idea is to have a subclass for each of the inputs that we create in loggly
    # URL to get the token from: https://venuedriver.loggly.com/inputs
  end


  # Public
  # This method sends a message to the Loggly API.
  #
  #
  # BEAWARE: That Loggle.new is an abstract class and lacks the token to authenticate with loggly.
  # You should subclass loggly and add a method named token that returns a string with the appropiate token.
  # SEE the method token on this class to know more about it
  #
  # EXAMPLES
  # USAGE: Let's say you have a class named TicketLoggly that subclasses Loggly.
  #
  # TicketLoggly.record("This works")
  #
  # You can also send a timestamp. For example:
  #
  # TicketLoggly.record("With a Timestamp", Time.now)
  #
  # Or you can get creative like:
  #
  # TicketLoggly.record(Event.last.attributes.to_json ,Time.now )

  def self.record(message, time=nil)
    self.send_to_loggly(message, time)
  end

  # Public
  #
  # This method behaves the same as record, but uses resque to send the message.
  #
  def self.async_record(message, time=nil)

    begin
      Resque.enqueue(LogglyResque, self.name, message, time)
    rescue => e
      puts e
      puts "There was an error cueing loggly"
    end
  end

  # Private
  #  We use this method internally to send messages to loggly.
  #  It is used by the Resque worker and by the record method.
  def self.send_to_loggly(message, time=nil)
    begin
      RestClient.post(self.url, (message + " | Time : " + time.to_s))
    rescue => e
      puts e
      puts "There was a problem making the HTTP call to Loggly"
    end
  end
end
