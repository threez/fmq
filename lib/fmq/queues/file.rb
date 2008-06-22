#
# Copyright (c) 2008 Vincent Landgraf
#
# This file is part of the Free Message Queue.
# 
# Foobar is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Foobar is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
# 
module FreeMessageQueue
  class FileQueue
    attr_accessor :manager

    def initialize()
      super
    end

    def poll()
      item = OpenStruct.new

      f = open(@file_path, "rb")
      item.data = f.read
      f.close
      
      item.content_type = @content_type
      item
    end

    def put(data)
      # do nothing
    end

    def size
      1 # there is always a message in the queue
    end
    
    def file=(path)
      @file_path = path
    end
    
    def content_type=(type)
      @content_type = type
    end
  end
end