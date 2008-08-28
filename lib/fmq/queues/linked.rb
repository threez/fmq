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
  # *DO* *NOT* *USE* *THIS* *QUEUE* *DIRECTLY* *IN* *THE* *QUEUE* *MANAGER*
  # it is not thread safe.
  # This Queue implements a FIFO based store in system memory.
  class LinkedQueue < BaseQueue
    def initialize(manager)
      super(manager)
      @last_message = @first_message = nil
    end
 
    # Remove all items from the queue
    def clear 
      while self.poll; end
    end
  
    # Put an item to the queue
    def put(message)
      return false if message.nil?
      
      add_message(message) # update stats and check constraints
      
      # insert at end of list
      if @first_message == nil
        # first and last item are same if there is no item to the queue
        @first_message = @last_message = message
      else
        # append the message to the end of the queue
        @last_message = @last_message.next = message
      end
      
      return true
    end
 
    # Return an message from the queue or nil if the queue is empty
    def poll()
      unless empty?
        # remove allways the first item
        message = @first_message
        
        # took it off
        @first_message = message.next
        @last_message = nil if @first_message.nil?
        message.next = nil # unlink the message
        remove_message(message) # update stats
      else
        return nil
      end
    end
  end
end
