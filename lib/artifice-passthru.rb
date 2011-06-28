require 'artifice' unless defined? Artifice

module Artifice # :nodoc:

  # Artifice.passthru! returns a Rack response created by making a *real* Net::HTTP 
  # request (using the Artifice::Passthru.last_request_info) and then turning 
  # the resulting Net::HTTPResponse object into a Rack response (which Artifice expects).
  def self.passthru!
    Artifice::Passthru.make_real_request_and_return_response!
  end

  # Given a constant (class or module), this gives it access to the *real* Net::HTTP so 
  # every request made from within this class/module will use the real Net::HTTP
  def self.use_real_net_http class_or_module
    Artifice::Passthru.setup_to_use_real_net_http class_or_module
  end

  # Artifice Passthru
  module Passthru

    # Simple class for storing information about the last #request that was made, 
    # allowing us to recreate the request
    class RequestInfo
      attr_accessor :address, :port, :request, :body, :block

      def initialize address, port, req, body, block
        self.address = address
        self.port    = port
        self.request = req
        self.body    = body
        self.block   = block
      end
    end

    # When Artifice::Passthru is included into Artifice::Net::HTTP, it uses "alias_method_chain" 
    # to override the #request method so we can get the arguments that were passed.
    def self.included base
      base.class_eval do
        alias_method :request_without_passthru_argument_tracking, :request
        alias_method :request, :request_with_passthru_argument_tracking
      end
    end

    # Returns the last information that were passed to Net::HTTP#request (which Artifice hijacked) 
    # so we can use these arguments to fire off a real request, if necessary.
    def self.last_request_info
      Thread.current[:artifice_passthru_arguments]
    end

    # Accepts and stores the last information that were passed to Net::HTTP#request (which Artifice hijacked) 
    # so we can use these arguments to fire off a real request, if necessary.
    def self.last_request_info= request_info
      Thread.current[:artifice_passthru_arguments] = request_info
    end

    # Makes a real Net::HTTP request and returns the response, converted to a Rack response
    def self.make_real_request_and_return_response!
      to_rack_response make_real_request(last_request_info)
    end

    # Given a Net::HTTPResponse, returns a Rack response
    def self.to_rack_response net_http_response
      # There's some voodoo magic going on that makes the real Net::HTTP#request method populate our response body for us?
      headers = net_http_response.instance_variable_get('@header').inject({}){|all,this| all[this.first] = this.last.join("\n"); all }
      [ net_http_response.code, headers, [net_http_response.body] ]
    end

    # Given the last_request_info (that would normally be passed to Net::HTTP#request), 
    # makes a real request and returns the Net::HTTPResponse
    def self.make_real_request request_info
      http = Artifice::NET_HTTP.new request_info.address, request_info.port
      http.request request_info.request, request_info.body, &request_info.block
    end

    # Given a constant (class or module), this gives it access to the *real* Net::HTTP so 
    # every request made from within this class/module will use the real Net::HTTP
    #
    # Taken from: http://matschaffer.com/2011/04/net-http-mock-cucumber/
    def self.setup_to_use_real_net_http class_or_module
      class_or_module.class_eval %{
        Net = ::Net.dup
        module Net
          HTTP = Artifice::NET_HTTP
        end
      }
    end

    # Simply stores the arguments that are passed and then calls "super" (request_without_passthru_argument_tracking)
    def request_with_passthru_argument_tracking req, body = nil, &block
      Artifice::Passthru.last_request_info = RequestInfo.new address, port, req, body, block
      request_without_passthru_argument_tracking req, body, &block
    end
  end
end

# Inject our #request method override into Artifice's implementation of Net::HTTP
Artifice::Net::HTTP.send :include, Artifice::Passthru
