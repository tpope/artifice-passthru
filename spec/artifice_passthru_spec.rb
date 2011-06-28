require 'rubygems'
require 'bundler/setup'
Bundler.require
require File.dirname(__FILE__) + '/../lib/artifice-passthru'
require 'minitest/autorun'

# Helper module for getting urls to test
module Urls
  def self.port
    @port ||= find_available_port
  end

  def self.root
    "http://localhost:#{port}/"
  end

  def self.passthru_uri
    URI.parse(root + 'passthru')
  end

  def self.mocked_uri
    URI.parse(root + 'mocked')
  end

  # Returns an available port number (taken from Capybara::Server)
  def self.find_available_port
    server = TCPServer.new('127.0.0.1', 0)
    server.addr[1]
  ensure
    server.close if server
  end
end

# Run a Rack application in the background that we can make *real* HTTP requests to
Thread.new do
  Rack::Handler::WEBrick.run lambda { |env|
    request = Rack::Request.new env
    if request.request_method == 'POST'
      [201, {'Custom' => 'posted value'}, ["You POSTed: #{request.POST.inspect}"]]
    else
      [202, {'Custom' => 'the value'}, ['Hi from REAL app']]
    end
  }, :Port => Urls.port
end

# Activate Artifice with our own Rack application (which can use Artifice.passthru! to allow real Net::HTTP requests)
Artifice.activate_with lambda { |env|
  if env['PATH_INFO'].include? 'passthru'
    Artifice.passthru!
  else
    [ 200, {}, ['Hi from Mock app'] ]
  end
}

# Example class that uses Net::HTTP, so we can use Artifice.use_real_net_http to give it access to the real Net::HTTP
class ExampleClass
  def self.class_get
    Net::HTTP.get_response Urls.mocked_uri
  end
  def instance_get
    Net::HTTP.get_response Urls.mocked_uri
  end
end

# Example module that uses Net::HTTP, so we can use Artifice.use_real_net_http to give it access to the real Net::HTTP
module ExampleModule
  def self.module_get
    Net::HTTP.get_response Urls.mocked_uri
  end
  def instance_get
    Net::HTTP.get_response Urls.mocked_uri
  end

  class InnerClass
    def self.class_get
      Net::HTTP.get_response Urls.mocked_uri
    end
    def instance_get
      Net::HTTP.get_response Urls.mocked_uri
    end
  end
end

describe Artifice::Passthru do

  it 'Artifice works as usual, returning mocked responses (for non-passthru requests)' do
    response = Net::HTTP.get_response Urls.mocked_uri
    response.body.must_equal 'Hi from Mock app'
  end

  it 'Artifice.passthru! returns the correct response body' do
    response = Net::HTTP.get_response Urls.passthru_uri
    response.body.must_equal 'Hi from REAL app'
  end

  it 'Artifice.passthru! returns the correct response code' do
    response = Net::HTTP.get_response Urls.passthru_uri
    response.code.must_equal '202'
  end

  it 'Artifice.passthru! returns the correct response headers' do
    response = Net::HTTP.get_response Urls.passthru_uri
    response['custom'].must_equal 'the value'
  end

  it 'Artifice.passthru! works with POSTs too' do
    response = Net::HTTP.post_form Urls.passthru_uri, { 'foo' => 'bar' }
    response.code.must_equal '201'
    response.body.must_equal 'You POSTed: {"foo"=>"bar"}'
    response['custom'].must_equal 'posted value'
  end

  it 'Artifice.use_real_net_http can give a class access to the real Net::HTTP' do
    ExampleClass.class_get.body.must_equal 'Hi from Mock app'
    ExampleClass.new.instance_get.body.must_equal 'Hi from Mock app'

    Artifice.use_real_net_http ExampleClass

    ExampleClass.class_get.body.must_equal 'Hi from REAL app'
    ExampleClass.new.instance_get.body.must_equal 'Hi from REAL app'
  end

  it 'Artifice.use_real_net_http can give a module access to the real Net::HTTP' do
    self.class.send :include, ExampleModule
    instance_get.body.must_equal 'Hi from Mock app'
    ExampleModule.module_get.body.must_equal 'Hi from Mock app'
    ExampleModule::InnerClass.class_get.body.must_equal 'Hi from Mock app'
    ExampleModule::InnerClass.new.instance_get.body.must_equal 'Hi from Mock app'

    Artifice.use_real_net_http ExampleModule

    instance_get.body.must_equal 'Hi from REAL app'
    ExampleModule.module_get.body.must_equal 'Hi from REAL app'
    ExampleModule::InnerClass.class_get.body.must_equal 'Hi from REAL app'
    ExampleModule::InnerClass.new.instance_get.body.must_equal 'Hi from REAL app'
  end

  it 'raises a useful exception if Artifice.passthru! is called but no previous response was made to Artifice' do
    Artifice::Passthru.last_request_info = nil

    lambda {
      Artifice.passthru!
    }.must_raise RuntimeError, 'Artifice.passthru! was called but no previous Artifice request was found to make via real Net::HTTP'
  end

end
