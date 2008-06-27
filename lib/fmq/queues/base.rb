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
  # This is the default message implementation in the queue system
  class Message
    attr_accessor :next, # reference to next Message if there is one
      :payload, # the content itself
      :created_at, # when came the message into the system
      :content_type, # the content type of the message
      :option # options hash (META-DATA) for the message
    
    # Create queue item
    def initialize(payload, content_type = "text/plain", created_at = Time.new)
      @payload = payload
      @created_at = created_at
      @content_type = content_type
      @option = {}
    end
    
    # Aize of item in bytes
    def bytes
      @payload.size
    end
  end
  
  # every queue has to have this interface
  class BaseQueue
    # QueueManager refrence
    attr_accessor :manager
  
    attr_reader :bytes, # the amount of space that is used by all messages in the queue
      :size # the size / depp of the queue = count of messages
    
    def initialize(manager)
      @manager = manager
      @bytes = 0
      @size = 0
    end
  end
end