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
    
    # Create a message item. The payload is often just a string
    def initialize(payload, content_type = "text/plain", created_at = Time.new)
      @payload = payload
      @created_at = created_at
      @content_type = content_type
      @option = {}
      if block_given? then
        yield self
      end
    end
    
    # Size of item in bytes
    def bytes
      @payload.size
    end
  end
  
  # All queue exceptions are raised using this class
  class QueueException < Exception
    attr_accessor :message, :backtrace
  
    # Create exception with message and backtrace (if needed)
    def initialize(message, callstack = [])
      @message = message
      @backtrace = callstack
    end
    
    # Returns the message of the exception
    def to_s
      @message
    end
  end
  
  # every queue has to have this interface
  class BaseQueue
    # QueueManager refrence
    attr_accessor :manager
    
    # This value is used to decribe that a constraint has no limit e.g.
    #   max_messages = INFINITE
    # means that there is no limitation for messages (by count)
    INFINITE = -1
  
    attr_reader :bytes, # the amount of space that is used by all messages in the queue
      :size, # the size / depp of the queue = count of messages
      :max_messages, # the max count of messages that can be in the queue
      :max_size # the max size (bytes) of messages that can be in the queue
    
    def initialize(manager)
      @manager = manager
      @bytes = 0
      @size = 0
      @max_size = @max_messages = INFINITE
    end
    
    # returns true if there is no message in the queue
    def empty?
      size == 0
    end
    
    # check that one can only set valid constraints
    def max_messages=(val)
      @max_messages = (val <= 0) ? BaseQueue::INFINITE : val
    end
    
    # check that one can only set valid constraints
    def max_size=(val)
      @max_size = (val <= 0) ? BaseQueue::INFINITE : val
    end
    
  protected
  
    # update queue size and memory usage (add one message)
    def add_message(message)
      check_constraints_with_new(message)
      
      @size += 1
      @bytes += message.bytes
      return message
    end
    
    # update queue size and memory usage (remove one message)
    def remove_message(message)
      @size -= 1
      @bytes -= message.bytes
      return message
    end
    
    # check all constraints that are available.
    # throws an exception if a constraint failed
    def check_constraints_with_new(message)
      check_max_size_constraint(message)
      check_max_messages_constraint(message)
    end
    
    # check if max size of messages will exceed with new message.
    # throws an exception if a constraint failed
    def check_max_size_constraint(message)
      if @max_size != INFINITE && (@max_size < self.bytes + message.bytes)
        raise QueueException.new("[Queue] The queue is full, max amount of space (#{@max_size} bytes) is exceeded", caller)
      end
    end
    
    # check if max count of messages will exceed with new message.
    # throws an exception if a constraint failed
    def check_max_messages_constraint(message)
      if @max_messages != INFINITE && (@max_messages < self.size + 1)
        raise QueueException.new("[Queue] The queue is full, max amount of messages (#{@max_messages}) is exceeded", caller)
      end
    end
  end
end

