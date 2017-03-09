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
    module API
        require 'zabbixapi'

        def zbx_connect()
            # if an http auth credential pair are set in the config use them
            if self.get_conf('zbx_http_user') and self.get_conf('zbx_http_password') and self.get_conf('zbx_username') and self.get_conf('zbx_password') and self.get_conf('zbx_url') then
                @zbx = ZabbixApi.connect(
                    :url            => self.get_conf('zbx_url'),
                    :user           => self.get_conf('zbx_username'),
                    :password       => self.get_conf('zbx_password'),
                    :http_user      => self.get_conf('zbx_http_user'),
                    :http_password  => self.get_conf('zbx_http_password')
                )
            # fall back to no http auth
            elsif self.get_conf('zbx_username') and self.get_conf('zbx_password') and self.get_conf('zbx_url') then
                @zbx = ZabbixApi.connect(
                    :url            => self.get_conf('zbx_url'),
                    :user           => self.get_conf('zbx_username'),
                    :password       => self.get_conf('zbx_password')
                )
            else
            	raise ErrorZabbixAuthentication
            end
        end

    	def zbx_connected?()
            if @zbx.client.auth.kind_of?(String) then
                # assume we are connected and authenticated
                return true
            else
                return false
            end
        end

        def zbx_host_exists?(hostname)
            self.debug_print("debug: processing #{hostname}")

            if self.zbx_connected?() then
                if @zbx.hosts.get_id(:host => hostname) then
                    self.debug_print("debug: #{hostname} exists")
                    return true
                else
                    self.debug_print("debug: #{hostname} not found")
                    return false
                end
            else
                self.debug_print("debug: please connect to the server")
            end
        end

        def zbx_group_exists?(group)
            self.debug_print("debug: checking #{group} exists")

            if self.zbx_connected?() then
                if @zbx.hostgroups.get_id(:name => group) then
                    self.debug_print("debug: #{group} exists")
                    return true
                else
                    self.debug_print("debug: #{group} not found")
                    return false
                end
            else
                self.debug_print("debug: please connect to the server")
            end
        end

        def zbx_create_group(group)
            unless self.zbx_group_exists?(group) then
                # create group
                @zbx.hostgroups.create(:name => group)
            end
        end

        def zbx_create_host(hostname,group,port,ip,dns,useip,templates)
            unless self.zbx_host_exists?(hostname) then
                template_ids = Array.new()
                if templates then
                    self.debug_print("debug: adding templates #{templates}")
                elsif templates = self.get_conf('zbx_default_templates') then
                    self.debug_print("debug: using default templates (#{templates})")
                else
                    self.debug_print("debug: no templates set")
                end

                templates.each do | tpl |
                    template_ids.push({'templateid' => @zbx.templates.get_id(:host => tpl)})
                end

                # create host
                self.debug_print("debug: creating #{hostname}")
                @zbx.hosts.create(
                    :host => hostname,
                    :interfaces => [
                        {
                            :type => 1,
                            :main => 1,
                            :ip => ip,
                            :dns => dns,
                            :port => port,
                            :useip => useip
                        }
                    ],
                    :groups => [ :groupid => @zbx.hostgroups.get_id(:name => group) ],
                    :templates => template_ids 
                )
            end
        end

        def zbx_get_all_hosts()
            @zbx_hosts = @zbx.hosts.all
        end

        def zbx_enable_host(hostname)
            # append hostname suffix if one is configured
            if self.get_conf('aws_dns_suffix') then
                self.debug_print("debug: appending #{self.get_conf('aws_dns_suffix')} to #{hostname}")
                hostname = hostname + self.get_conf('aws_dns_suffix')
            end

            @zbx.hosts.update(
                :hostid => @zbx.hosts.get_id(:host => hostname),
                :status => 0
            )
        end

        def zbx_disable_host(hostname)
            # append hostname suffix if one is configured
            if self.get_conf('aws_dns_suffix') then
                self.debug_print("debug: appending #{self.get_conf('aws_dns_suffix')} to #{hostname}")
                hostname = hostname + self.get_conf('aws_dns_suffix')
            end

            @zbx.hosts.update(
                :hostid => @zbx.hosts.get_id(:host => hostname),
                :status => 1
            )
        end

        def zbx_process_host(options = {})
            unless options[:hostname] and options[:group] and options[:port] and options[:ip] and options[:dns] and options[:useip] then
                puts "error: not enough parameters"
                exit
            end
                
            # append hostname suffix if one is configured
            if self.get_conf('aws_dns_suffix') then
                self.debug_print("debug: appending #{self.get_conf('aws_dns_suffix')} to #{options[:hostname]}")
                hostname = options[:hostname] + self.get_conf('aws_dns_suffix')
                dns = options[:dns] + self.get_conf('aws_dns_suffix')
            else
                hostname = options[:hostname]
                dns = options[:dns]
            end

            self.debug_print("debug: processing #{hostname}")

            # create group
            self.zbx_create_group(options[:group])

            # create host
            self.zbx_create_host(hostname,options[:group],options[:port],options[:ip],dns,options[:useip],options[:templates])
        end
    end
end
