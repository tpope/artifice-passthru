require 'artifice-passthru/core'

# Inject our #request method override into Artifice's implementation of Net::HTTP
require 'artifice' unless defined? Artifice::Net::HTTP
Artifice::Net::HTTP.send :include, Artifice::Passthru
