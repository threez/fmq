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
require "ostruct"

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
    # Returns the queue that is passed otherwise nil
    attr_reader :queue
    
    # <b>true</b> to let the queue manager create a queue automaticly
    attr_writer :auto_create_queues
  
    # Returns the queue constrains as a hash. The hash has the following structure:
    #  {
    #    :max_size => "100mb",
    #    :max_messages => 1000
    #  }
    attr_reader :queue_constraints
    
    # This value is used to decribe that a constraint has no limit e.g.
    #  :max_messages => INFINITE
    # means that there is no limitation for messages
    INFINITE = -1
    
    # this is the default queue class if no other is specified this
    # class will be created when setting up a queue
    DEFAULT_QUEUE_CLASS = FreeMessageQueue::SyncronizedQueue
  
    # setup the queue manager using the configuration from the configuration
    # file (which is basically a hash)
    def initialize()
      @queue = {}
      @queue_constraints = {}
      @log = FreeMessageQueue.logger
      @auto_create_queues = true
    end
    
    # returns if the creation of queues should be done on demand
    # (if someone sends a post to a queue)
    def auto_create_queues?
      @auto_create_queues == true
    end
   
    # Create a queue (<em>name</em> => <em>path</em>). The path must contain a leading "/" and a 3 character name
    # at minimum. Exceptions will be raised if the queue allready exists.
    def create_queue(name, max_messages = INFINITE, max_size = INFINITE, default_class = DEFAULT_QUEUE_CLASS)
      # path must begin with /
      raise QueueManagerException.new("[QueueManager] Leading / in path '#{name}' missing", caller) if name[0..0] != "/"
      
      # path must have a minimus lenght of 3 character
      raise QueueManagerException.new("[QueueManager] The queue path '#{name}' is to short 3 character is minimum", caller) if name.size - 1 < 3
      
      # don't create a queue twice
      raise QueueManagerException.new("[QueueManager] The queue '#{name}' allready exists", caller) if queue_exists? name
    
      @log.info("[QueueManager] Create queue '#{name}' {type: #{default_class}, max_messages: #{max_messages}, max_size: #{max_size}}")

      @queue[name] = default_class.new(self)
      @queue_constraints[name] = {
        :max_messages => max_messages,
        :max_size => max_size
      }
      
      @queue[name]
    end
    
    # create a queue using a block. The block can be used to set configuration
    # options for the queue
    def setup_queue(queue_class = DEFAULT_QUEUE_CLASS, &configure_queue)   
      queue_settings = OpenStruct.new
      configure_queue.call(queue_settings)
      create_queue_from_config(queue_class, queue_settings.marshal_dump)
    end
   
    # Delete the queue by name (path)
    def delete_queue(name)
      if @queue[name]
        @log.info("[QueueManager] Delete queue '#{name}' with #{@queue[name].size} messages")
        @queue[name].clear
        @queue.delete name
        true
      else
        raise QueueManagerException.new("[QueueManager] There is no queue '#{name}'", caller)
      end
    end
   
    # This returns one message from the passed queue
    def poll(name)
      if @queue[name]
        @log.debug("[QueueManager] Poll from queue '#{name}' with #{@queue[name].size} messages")
        if @queue[name].respond_to? :poll
          queue_item = @queue[name].poll
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
      unless @queue[name]
        # only auto create queues if it is configured
        if auto_create_queues?
          create_queue(name) 
        else
          raise QueueManagerException.new("[QueueManager] There is no queue '#{name}'", caller)
        end
      end
      
      # check max size constraints
      if @queue_constraints[name][:max_size] != INFINITE &&
        @queue_constraints[name][:max_size] < queue[name].bytes + message.bytes
        raise QueueManagerException.new("[QueueManager] The queue '#{name}' is full, max amount of space (#{@queue_constraints[name][:max_size]}) is exceeded", caller)
      end
      
      # check max messages constraints
      if @queue_constraints[name][:max_messages] != INFINITE &&
        @queue_constraints[name][:max_messages] < queue[name].size + 1
        raise QueueManagerException.new("[QueueManager] The queue '#{name}' is full, max amount of messages (#{@queue_constraints[name][:max_messages]}) is exceeded", caller)
      end
   
      @log.debug("[QueueManager] put message to queue '#{name}' with #{@queue[name].size} messages")
      if @queue[name].respond_to? :put
        @queue[name].put(message)
      else
        raise QueueManagerException.new("[QueueManager] You can't put to queue '#{name}'", caller)
      end
    end
    
    alias post put

    # Returns the names (paths) of all queues managed by this queue manager
    def queues
      @queue.keys
    end
   
    # Returns the size (number of messages)
    def queue_size(name)
      @queue[name].size
    end
    
    # Returns the byte size of the queue
    def queue_bytes(name)
      @queue[name].bytes
    end
    
    # Is the name (path) of the queue in use allready
    def queue_exists?(name)
      !queue[name].nil?
    end
    
    # setup a this queue manager block need to be passed
    def setup(&config)
      config.call(self)
    end
    
  private
  
    # create a queue from a configuration hash.
    # The <em>queue_config</em> contains the following parameter:
    # * path: the path to the queue (with leading "/" and 3 characters at minimum) e.g. "/test_queue"
    # * [optional] max_size: the maximum size e.g. "10mb", "100kb", "2gb" or (black or -1) for infinite
    # * [optional] max_messages: the maximim messages that can be in the queue e.g. 1500 or (black or -1) for infinite
    # All other parameter will be send to the queue directly using a naming convention. So if you have the extra parameter
    #  expire_date = "1h"
    # the QueueManager will set the expire date using this assignment 
    #  queue.expire_date = "1h"
    # therefore your queue must implement this method
    #  def expire_date=(time)
    #    @expires_after = parse_seconds(time)
    #  end
    def create_queue_from_config(queue_class, queue_config)
      # path need to be specified
      raise QueueManagerException.new("[QueueManager] There is now path specified for queue", caller) if queue_config[:path].nil?
      path = queue_config[:path]
      queue_config.delete :path
      
      @log.debug("[QueueManager] setup queue from config '#{path}'")

      # set max size parameter -- this parameter is optional
      max_size = str_bytes(queue_config[:max_size])
      max_size = INFINITE if max_size.nil? || max_size <= 0
      queue_config.delete :max_size

      # set max messages parameter -- this parameter is optional
      max_messages = queue_config[:max_messages].to_i
      max_messages = INFINITE if max_messages.nil? || max_messages <= 0
      queue_config.delete :max_messages

      queue = create_queue(path, max_messages, max_size, queue_class)

      if queue_config.size > 0
        @log.debug("[QueueManager] Configure addional parameters for queue '#{path}'; parameter: #{queue_config.inspect}")
        for method_name in queue_config.keys
          queue.send(method_name.to_s + "=", queue_config[method_name])
        end
      end
    end
  
    # Retuns count of bytes to a expression with kb, mb or gb
    # e.g 10kb will return 10240
    def str_bytes(str)
      case str
        when /([0-9]+)kb/i
          bs = $1.to_i * 1024 
        when /([0-9]+)mb/i
          bs = $1.to_i * 1024 * 1024 
        when /([0-9]+)gb/i
          bs = $1.to_i * 1024 * 1024 * 1024
        else
          bs = INFINITE
      end
      bs
    end
  end
end
