#!/usr/bin/env ruby
#
#   Author: Tom Llewellyn-Smith <tom@onixconsulting.co.uk>
#   Copyright: © Onix Consulting Limited 2012-2015. All rights reserved.
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
require 'optparse'
require 'awsbix'

options = {}
OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"
    opts.on("-c CONFIG","--config", "YAML config") do |c|
        options[:config] = c
    end
end.parse!

config = options[:config] ||= 'bin/config.yaml'

awsbix = Awsbix.new(config)

# connect to host defined in config.yaml
awsbix.zbx_connect()

# process hosts, if no :regex or :filter mode is provided defaults to include all hosts in AWS account
awsbix.aws_get_hosts(:regex => %r{security_group_to_match},:filter => 'include').each do |host|
    host.security_groups.each do | sg |
        awsbix.zbx_process_host(
            :hostname   => host.tags['Name'],
            :group      => sg.name,
            :port       => 10050,
            :ip         => host.private_ip_address,
            :dns        => host.tags['Name'],
            :templates  => ['Template OS Linux'], # optional, can be set in the config.yaml file
            :useip      => 0
        )
    end
end
