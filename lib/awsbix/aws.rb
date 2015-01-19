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
        def aws_get_hosts()
            @ec2_hosts = Array.new

            # get sg to ignore or process based on zbx_filter_model
            case self.get_conf('zbx_filter_model')
                when 'exclude'
                    excluded_security_groups = self.get_conf('zbx_exclude_security_group')
                when 'include'
                    included_security_groups = self.get_conf('zbx_include_security_group')
            end

            self.ec2_connect()
            # loop through all hosts, across all regions in config
            self.aws_get_regions().each do |region|
                self.debug_print("info: processing #{region}")
                AWS.memoize do
                    @ec2.regions[region].instances.each do | inst |
                        if inst.status.match(/running/) then
                            inst.security_groups.each do | sg |
                                case self.get_conf('zbx_filter_model')
                                    when 'exclude'
                                        # do not process if sg is excluded
                                        unless excluded_security_groups.include?(sg.name) then
                                            # do not push if already present
                                            unless @ec2_hosts.include?(inst) then
                                                @ec2_hosts.push(inst)
                                            end
                                        end
                                    when 'include'
                                        # process if sg is included
                                        if included_security_groups.include?(sg.name) then
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
            return @ec2_hosts
        end
    end
end
