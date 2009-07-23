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

# add kb, mb and gb methods for easy use in the config file
class Fixnum
  def kb
    self * 1024
  end
  
  def mb
    self.kb * 1024
  end
  
  def gb
    self.mb * 1024
  end
end

module FreeMessageQueue
  # All queue manager exceptions are raised using this class
  class QueueManagerException < Exception
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

  # The queue manager is one of the core components of the system.
  # This component manages the queues by pathname and checks on the
  # corresponding constraints. Every queue that is created by this
  # queue manager will get a reference (<em>manager</em>) for later use.
  class QueueManager
    # <b>true</b> to let the queue manager create a queue automaticly
    attr_writer :auto_create_queues
    
    # this is the default queue class if no other is specified this
    # class will be created when setting up a queue
    DEFAULT_QUEUE_CLASS = FreeMessageQueue::SyncronizedQueue
  
    # setup the queue manager using the configuration from the configuration
    # file (which is basically a hash)
    def initialize(auto_create_queues = true, &block)
      @queues = {}
      @log = FreeMessageQueue.logger
      @auto_create_queues = auto_create_queues
      instance_eval(&block) if block_given?
    end
    
    # returns if the creation of queues should be done on demand
    # (if someone sends a post to a queue)
    def auto_create_queues?
      @auto_create_queues == true
    end
    
    # create a queue using a block. The block can be used to set configuration
    # options for the queue
    def setup_queue(path, queue_class = nil, &block)
      check_queue_name(path)
      queue_class ||= DEFAULT_QUEUE_CLASS
      queue_class = FreeMessageQueue::const_get(queue_class) if queue_class.class == String
      queue_object = queue_class.new(self)
      block.call(queue_object) if block_given?
      @queues[path] = queue_object
      @log.info("[QueueManager] Create queue '#{path}' {type: #{queue_class}, max_messages: #{queue_object.max_messages}, max_size: #{queue_object.max_size}}")
      return queue_object
    end
   
    # Delete the queue by name (path)
    def delete_queue(name)
      if queue_exists? name
        @log.info("[QueueManager] Delete queue '#{name}' with #{queue(name).size} messages")
        queue(name).clear if queue(name).respond_to? :clear
        @queues.delete name
        true
      else
        raise QueueManagerException.new("[QueueManager] There is no queue '#{name}'", caller)
      end
    end
   
    # This returns one message from the passed queue
    def poll(name)
      if queue_exists? name
        @log.debug("[QueueManager] Poll from queue '#{name}' with #{queue(name).size} messages")
        if queue(name).respond_to? :poll
          queue_item = queue(name).poll
        else
          raise QueueManagerException.new("[QueueManager] You can't poll from queue '#{name}'", caller)
        end
      else
        raise QueueManagerException.new("[QueueManager] There is no queue '#{name}'", caller)
      end
    end
      
    alias get poll
   
    # Puts a message (<em>data</em>) to the queue and checks if the constraints are vaild otherwise
    # it will raise a QueueManagerException. If <em>auto_create_queues</em> is set to *true* the queue
    # will be generated if there isn't a queue with the passed name (path). Otherwise
    # it will raise a QueueManagerException if the passed queue doesn't exists.
    def put(name, message)
      # check for auto createing queues if they are not available
      unless queue_exists? name
        # only auto create queues if it is configured
        if auto_create_queues?
          setup_queue(name) 
        else
          raise QueueManagerException.new("[QueueManager] There is no queue '#{name}'", caller)
        end
      end
   
      @log.debug("[QueueManager] put message to queue '#{name}' with #{queue(name).size} messages")
      if queue(name).respond_to? :put
        queue(name).put(message)
      else
        raise QueueManagerException.new("[QueueManager] You can't put to queue '#{name}'", caller)
      end
    end
    
    alias post put

    # Returns the names (paths) of all queues managed by this queue manager
    def queues
      @queues.keys
    end
    
    # Is the name (path) of the queue in use allready
    def queue_exists?(name)
      !queue(name).nil?
    end
    
    # returns the queue qith the passed name
    def queue(name)
      return @queues[name]
    end
    
  private  
    
    # Create a queue (<em>name</em> => <em>path</em>). The path must contain a leading "/" and a 3 character name
    # at minimum. Exceptions will be raised if the queue allready exists.
    def check_queue_name(name)
      # path must begin with /
      raise QueueManagerException.new("[QueueManager] Leading / in path '#{name}' missing", caller) if name[0..0] != "/"
      
      # path must have a minimus lenght of 3 character
      raise QueueManagerException.new("[QueueManager] The queue path '#{name}' is to short 3 character is minimum", caller) if name.size - 1 < 3
      
      # don't create a queue twice
      raise QueueManagerException.new("[QueueManager] The queue '#{name}' allready exists", caller) if queue_exists? name
    end
  end
end

