require 'spec_helper'

$port = find_available_port
$url  = "http://localhost:#{$port}/"

# Run a Rack application in the background that we can make *real* HTTP requests to
Thread.new do
  Rack::Handler::WEBrick.run lambda { |env|
    request = Rack::Request.new env
    [202, {'Custom' => 'the value'}, ['Hi from REAL app']]
  }, :Port => $port
end

# Activate Artifice with our own Rack application (which can use Artifice.passthru! to allow real Net::HTTP requests)
Artifice.activate_with lambda { |env|
  if env['PATH_INFO'].include? 'real'
    Artifice.passthru!
  else
    [ 200, {}, ['Hi from rack app'] ]
  end
}

describe Artifice::Passthru do

  it 'Rack app can mock Net::HTTP response' do
    open($url + 'foo').read.must_equal 'Hi from rack app'
  end

  it 'Artifice.passthru! returns the result of making a real Net::HTTP response' do
    open($url + 'real').read.must_equal 'Hi from REAL app'
  end

  it 'Artifice.passthru! returns the correct response code' do
    response = Net::HTTP.get_response URI.parse($url + 'real')
    response.code.must_equal '202'
  end

  it 'Artifice.passthru! returns the correct response headers' do
    response = Net::HTTP.get_response URI.parse($url + 'real')
    puts response.instance_variable_get('@header').inspect
    response['custom'].must_equal 'the value'
  end

end
