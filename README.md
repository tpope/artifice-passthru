Artifice::Passthru
==================

[Artifice][] is a great way to mock HTTP requests in your Ruby applications, 
sending all Net::HTTP requests to a Rack application.

That's great until you find that, for one reason or another, you *actually* need 
to make **real** HTTP requests!

There are a few reasons why you might need to do this:

 - You want to test that real HTTP requests work
 - Your test suite uses HTTP to communicate with its testing tools (eg. Capybara/Selenium requires HTTP) 
 - Your test suite calls lots of real APIs and you want to iteratively refactor it to use Artifice
 - ?

Usage
-----

```ruby
require 'artifice/passthru'

# If you want to give a class or module (and all of its subclasses)
# access to the real Net::HTTP, you can #use_real_net_http
Artifice.use_real_net_http MyModule

Artifice.activate_with lambda { |env|
  if env['SERVER_NAME'] == 'api.twitter.com'
    # Inside of your Artifice Rack application, you can call Artifice.passthru! which:
    # - looks at the current Artifice request
    # - makes a real HTTP request
    # - returns a Rack response representing the actual HTTP response that was returned
    Artifice.passthru!   # <--- will make the real HTTP call and return the response
  else
    # return faked responses using your Rack application as you normally would
    [ 200, {}, ['Hi!'] ]
  end
}
```

That's all!

License
-------

Artifice::Passthru is released under the MIT license.

[artifice]: https://github.com/wycats/artifice
