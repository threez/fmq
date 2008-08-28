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
require File.dirname(__FILE__) + '/base'

module FreeMessageQueue
  # This queue returns everytime the same file. This is useful during debugging or
  # to serve the admin page.
  # 
  #  queue_manager = FreeMessageQueue::QueueManager.new(true) do
  #    setup_queue "/dummy/file", FreeMessageQueue::FileQueue do |q|
  #      q.file = "tmp/default_message.yml"
  #      q.content_type = "text/yaml"
  #    end
  #  end
  #
  # *NOTE* the put method is not implemented in this queue. It is a poll only queue.
  class FileQueue < BaseQueue
    # Return the file and content type
    def poll()
      file_content = ""
      File.open(@file_path, "rb") do |f|
        file_content = f.read
      end
      
      @bytes = file_content.size
      Message.new(file_content, @content_type)
    end
    
    # *CONFIGURATION* *OPTION*
    # sets the path to the file that should be read
    def file=(path)
      @file_path = path
    end
    
    # *CONFIGURATION* *OPTION*
    # sets the content_type of the file. This option
    # make sense if you want to test with the webbrowser.
    def content_type=(type)
      @content_type = type
    end
  end
end
