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
    module Conf
        require 'yaml'

        def read(file)
            if (File.exists?(file)) then
                @conf = YAML.load_file(file)
                return @conf
            else
                raise Awsbix::ErrorNoConfiguration
            end
        end

        def configured?()
            # return 1 if config exists
            if @conf then
                return true
            else
                return false
            end
        end

        def get_conf(item)
            if self.configured?() then
                @conf[item]
            else
                raise Awsbix::ErrorNoConfiguration
            end
        end
    end
end
