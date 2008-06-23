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
module FreeMessageQueue
  # This queue returns everytime the same file. This is useful during debugging or
  # to serve the admin page.
  # 
  # configuration sample:
  #  queue-manager:
  #    auto-create-queues: true
  #    defined-queues:
  #      admin-page-index:
  #      path: /admin/index
  #      class: FreeMessageQueue::FileQueue
  #      file: admin-interface/index.html
  #      content-type: text/html
  #
  # *NOTE* the put method is not implemented in this queue. It is a poll only queue.
  class FileQueue
    # QueueManager refrence
    attr_accessor :manager
    
    # Bytes are -1 at startup but fill after first poll. Size is allways 1 message
    attr_reader :bytes, :size
    
    def initialize
      # there is always one message (the file) in the queue
      @bytes = -1
      @size = 1
    end

    # Return the file and content type
    def poll()
      item = OpenStruct.new

      f = open(@file_path, "rb")
      item.data = f.read
      @bytes = item.data.size
      f.close
      
      item.content_type = @content_type
      item
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