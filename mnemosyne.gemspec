lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mnemosyne/version'

Gem::Specification.new do |s|
  s.name        = 'mnemosyne'
  s.version     = ::Mnemosyne.version
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.summary     = 'Mnemosyne Backup Solution'
  s.description = 'A simple solution for AWS AMIs and RDS Snapshots'
  s.authors     = ['Jonathan Gnagy']
  s.email       = 'jgnagy@knuedge.com'
  s.required_ruby_version = '~> 2.0'
  s.files       = [
    'bin/mnemosyne',
    'lib/mnemosyne.rb',
    'lib/mnemosyne/config.rb',
    'lib/mnemosyne/exception.rb',
    'lib/mnemosyne/clients/ec2.rb',
    'lib/mnemosyne/clients/rds.rb',
    'lib/mnemosyne/resources/ec2_instance.rb',
    'lib/mnemosyne/resources/rds_instance.rb',
    'lib/mnemosyne/version.rb',
    'LICENSE',
    'README.md',
    'samples/example-config.yml',
    'samples/example-iam-policy.json'
  ]
  s.executables << 'mnemosyne'
  s.bindir      = 'bin'
  s.license     = 'MIT'
  s.platform    = Gem::Platform::RUBY
  s.post_install_message = 'Thanks for installing Mnemosyne!'
  s.homepage    = 'https://github.com/knuedge/mnemosyne'

  # Dependencies
  s.add_runtime_dependency 'aws-sdk',  '~> 2'
  s.add_runtime_dependency 'colorize', '~> 0.7'
  s.add_runtime_dependency 'mime-types', '~> 2.6'

  s.add_development_dependency 'rspec',   '~> 3.1'
  s.add_development_dependency 'rubocop', '~> 0.35'
  s.add_development_dependency 'yard',    '~> 0.8'
end
