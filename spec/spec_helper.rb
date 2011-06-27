require 'rubygems'
require 'bundler/setup'
Bundler.require
require File.dirname(__FILE__) + '/../lib/artifice-passthru'
require 'open-uri'
require 'minitest/autorun'

# Returns an available port number (taken from Capybara::Server)
def find_available_port
  server = TCPServer.new('127.0.0.1', 0)
  server.addr[1]
ensure
  server.close if server
end
