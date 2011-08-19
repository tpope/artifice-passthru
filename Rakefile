require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = 'spec/*_spec.rb'
  t.libs    = %w[ lib spec ]
  t.options = '-v'
end

task :default => :test
