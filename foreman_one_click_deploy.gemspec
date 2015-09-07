require File.expand_path('../lib/foreman_one_click_deploy/version', __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name        = 'foreman_one_click_deploy'
  s.version     = ForemanOneClickDeploy::VERSION
  s.date        = Date.today.to_s
  s.authors     = ['Elad Shmitanka']
  s.email       = ['elad@myheritage.com']
  s.homepage    = 'https://github.com/myheritage/foreman_one_click_deploy'
  s.summary     = 'A foreman plugin to allow One-Click creation of a virtual host'
  # also update locale/gemspec.rb
  s.description = 'The goal is a plugin that will allow an instant no-questions-asked creation of a virtual machine based on an image.
                   In addition, there will be a rake task that gets a vitual machine and updates the image according to the VM (useful to catch
                   on DB migrations, data changes etc...'

  s.files = Dir['{app,config,db,lib,locale}/**/*'] + ['LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'deface'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rdoc'
end
