Gem::Specification.new do |s|
  s.name        = 'awsbix'
  s.version     = '0.0.8'
  s.date        = '2017-03-09'
  s.summary     = "add/remove hosts to Zabbix"
  s.description = "automates adding/removing hosts to Zabbix"
  s.authors     = ["Tom Llewellyn-Smith"]
  s.email       = 'code@onixconsulting.co.uk'
  s.files       = [
    'bin/config.yaml',
    'lib/awsbix/api.rb',
    'lib/awsbix/aws.rb',
    'lib/awsbix/base.rb',
    'lib/awsbix/conf.rb',
    'lib/awsbix/error.rb',
    'lib/awsbix.rb',
    'LICENSE',
    'README.md'
  ]
  s.executables << 'add-hosts.rb'
  s.homepage    = 'https://github.com/brahman81/awsbix'
  s.license       = 'GPL-3.0'
  s.required_ruby_version = '>= 1.9.2'
  s.add_runtime_dependency "aws-sdk", "~> 1.60"
  s.add_runtime_dependency "zabbixapi", "~> 2.0"
end
