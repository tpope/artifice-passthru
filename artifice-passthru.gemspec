require File.expand_path('../lib/artifice-passthru/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'artifice-passthru'
  s.version     = Artifice::Passthru::VERSION
  s.summary     = 'Easily use real Net::HTTP with Artifice'
  s.description = 'Artifice extension that allows you to let certain requests pass thru to use HTTP'
  s.author      = 'remi'
  s.email       = 'remi@remitaylor.com'
  s.homepage    = 'https://github.com/remi/artifice-passthru'
  s.files       = Dir['README*', 'lib/**/*.rb']

  s.add_dependency 'artifice'
end
