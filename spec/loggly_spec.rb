require Dir.pwd + '/lib/loggly'

require 'resque'
require 'fakeweb'
require 'rspec'
require 'resque_unit'

#Resque.inline = true

class TestLoggly < Loggly
  def self.token
    'test'
  end
end

ok_response = "{\"response\":\"ok\"}"
bad_response = "There was a problem making the HTTP call to Loggly"

def mock_url_with(url, response)
  FakeWeb.register_uri(:post, url, :body => response)
end

mock_url_with("http://logs.loggly.com/inputs/test", ok_response)

describe Loggly do

  include ResqueUnit::Assertions
  include Test::Unit::Assertions

  it "sends the message to loggly" do
    TestLoggly.record("This is a test").should == ok_response
  end

  it "can send an optional parameters" do
    TestLoggly.record("Our message", Time.now.to_s).should == ok_response
  end

  it "can send the message async" do
    TestLoggly.async_record("sk")
    assert_queued(LogglyResque)
  end

end
