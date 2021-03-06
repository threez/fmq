#
# Copyright (c) 2008 Vincent Landgraf
#
# This file is part of the Free Message Queue.
# 
# Free Message Queue is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Free Message Queue is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Free Message Queue.  If not, see <http://www.gnu.org/licenses/>.
#

# load the rack enviroment
begin
  require "rack"
rescue LoadError
  require "rubygems"
  require "rack"
end

# load all queues and manager and server
Dir.glob(File.dirname(__FILE__) + "/fmq/queues/*.rb").each do |file|
  require file
end

# load all parts in right order
['boot', 'admin', 'client', 'server'].each do |file|
  require File.dirname(__FILE__) + "/fmq/#{file}"
end
