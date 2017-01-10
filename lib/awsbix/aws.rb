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
class Awsbix
    module AmazonWebServices
        require 'aws-sdk'

        def aws_get_regions()
            # return an array of all regions in config
            self.get_conf('aws_regions')
        end

        def ec2_connect()
            # credentials -> IAM role -> Raise exception
            if self.get_conf('aws_access_key') and self.get_conf('aws_secret_key') then
                AWS.config(
                    :access_key_id => self.get_conf('aws_access_key'),
                    :secret_access_key => self.get_conf('aws_secret_key')
                )
                @ec2 = AWS::EC2.new()
            else
                # try IAM role
                begin
                    @ec2 = AWS::EC2.new()
                rescue
                    raise ErrorAWSAuthentication
                end
            end
        end

        # retrieve non-excluded and running EC2 hosts
        # {:filter => 'exclude|include', :regex => %r{}}
        def aws_get_hosts(options = {})
            # if no filter mode is provided default to 'include' 
            options[:filter] ||= 'include'
            # if no regex is provided default to '.*' 
            options[:regex] ||= %r{.*}
            # instance_status defaults to 'running' 
            options[:instance_status] ||= 'running'
            @ec2_hosts = Array.new

            self.ec2_connect()
            # loop through all hosts, across all regions in config
            self.aws_get_regions().each do |region|
                self.debug_print("info: processing #{region}")
                AWS.memoize do
                    @ec2.regions[region].instances.each do | inst |
                        if inst.status.match(/#{options[:instance_status]}/) then
                            inst.security_groups.each do | sg |
                                if options[:regex].is_a?(Regexp) then
                                    case options[:filter]
                                        when 'exclude'
                                            # do not process if sg is excluded
                                            unless sg.name.match(options[:regex]) then
                                                # do not push if already present
                                                unless @ec2_hosts.include?(inst) then
                                                    @ec2_hosts.push(inst)
                                                end
                                            end
                                        when 'include'
                                            # process if sg is included
                                            if sg.name.match(options[:regex]) then
                                                # do not push if already present
                                                unless @ec2_hosts.include?(inst) then
                                                    @ec2_hosts.push(inst)
                                                end
                                            end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return @ec2_hosts
        end
    end
end
