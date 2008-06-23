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
  # Simple queue item class is used, because it is 
  # considered to be faster than ostruct
  class QueueItem
    attr_accessor :next, :data, :created_at
 
    # Create queue item
    def initialize(data, created_at = Time.new)
      @data = data
      @created_at = created_at
    end
 
    # Aize of item in bytes
    def bytes
      @data.size
    end
  end
 
  # *DO* *NOT* *USE* *THIS* *QUEUE* *DIRECTLY* *IN* *THE* *QUEUE* *MANAGER*
  # it is not thread safe.
  # This Queue implements a FIFO based store in system memory.
  class LinkedQueue
    attr_reader :size, :bytes
 
    def initialize()
      @size = 0
      @first_item = nil
      @last_item = nil
      @bytes = 0
    end
 
    # Remove all items from the queue
    def clear 
      if size > 0
        while self.poll; end
      end
    end
  
    # Put an item to the queue
    def put(data)
      return false if data == nil
 
      # create item
      qi = QueueItem.new(data)
 
      # insert at end of list
      if @first_item == nil
        @first_item = @last_item = qi
      else
        @last_item.next = qi
      end
      @last_item = qi
 
      # update queue size and memory usage
      @size += 1
      @bytes += qi.bytes
      true
    end
 
    # Return an item from the queue
    def poll()
      if @size > 0
        # remove allways the first item
          qi = @first_item
 
        # cleanup list
        if @first_item == @last_item # just 1 element is in the list
          @first_item = @last_item = nil
        else
          @first_item = @first_item.next
        end
        qi.next = nil # remove link to next item
 
        # update queue size and memory usage
        @size -= 1
        @bytes -= qi.bytes
        return qi
      else
        return nil
      end
    end
  end
end
