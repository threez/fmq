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
  class QueueManagerException < RuntimeError
    attr_accessor :message, :backtrace
  
    def initialize(message, callstack)
      @message = message
      @backtrace = callstack
    end
    
    def to_s
      @message
    end
  end

  class QueueManager
    INFINITE = -1
  
    def initialize(config)
      @queue = {}
      @config = config
      @queue_constraints = {}
      @log = FreeMessageQueue.logger
      setup_queue_manager()
    end
    
    def auto_create_queues?
      @config["auto-create-queues"]
    end
   
    def create_queue(name, max_messages = INFINITE, max_size = INFINITE, default_class = FreeMessageQueue::SyncronizedQueue)
      # path must begin with /
      raise QueueManagerException.new("[QueueManager] Leading / in path '#{name}' missing", caller) if name[0..0] != "/"
      
      # path must have a minimus lenght of 3 character
      raise QueueManagerException.new("[QueueManager] The queue path '#{name}' is to short 3 character is minimum", caller) if name.size - 1 < 3
      
      # don't create a queue twice
      raise QueueManagerException.new("[QueueManager] The queue '#{name}' allready exists", caller) if queue_exists? name
    
      @log.info("[QueueManager] Create queue '#{name}' {type: #{default_class}, max_messages: #{max_messages}, max_size: #{max_size}}")

      @queue[name] = default_class.new
      @queue[name].manager = self
      @queue_constraints[name] = {
        :max_messages => max_messages,
        :max_size => max_size
      }
      
      @queue[name]
    end
   
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
   
    def poll(name)
      if @queue[name]
        @log.debug("[QueueManager] Poll from queue '#{name}' with #{@queue[name].size} messages")
        queue_item = @queue[name].poll
      else
        raise QueueManagerException.new("[QueueManager] There is no queue '#{name}'", caller)
      end
    end
   
    def put(name, data)
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
        @queue_constraints[name][:max_size] < queue(name).bytes + data.size
        raise QueueManagerException.new("[QueueManager] The queue '#{name}' is full, max amount of space (#{@queue_constraints[name][:max_size]}) is exceeded", caller)
      end
      
      # check max messages constraints
      if @queue_constraints[name][:max_messages] != INFINITE &&
        @queue_constraints[name][:max_messages] < queue(name).size + 1
        raise QueueManagerException.new("[QueueManager] The queue '#{name}' is full, max amount of messages (#{@queue_constraints[name][:max_messages]}) is exceeded", caller)
      end
   
      @log.debug("[QueueManager] put message to queue '#{name}' with #{@queue[name].size} messages")
      @queue[name].put(data)
    end
   
    def queues
      @queue.keys
    end
   
    def queue_size(name)
      @queue[name].size
    end
    
    def queue_constraints(name)
      @queue_constraints[name]
    end
   
    def queue(name)
      @queue[name]
    end
    
    def queue_exists?(name)
      !queue(name).nil?
    end
    
    # create a queue from a configuration hash
    # <em>queue_name</em> this name is just for debugging and organizing the queue
    # <em>queue_config</em> here you will pass the parameter:
    # * path:
    # * [optional] max-size: the maximum size e.g. 10mb
    # * [optional] max-messages: the maximim messages that can be in the queue e.g. 9999999
    # * [optional] class: the class that implements this queue e.g. FreeMessageQueue::SystemQueue
    def create_queue_from_config(queue_name, queue_config)
      @log.debug("[QueueManager] setup queue from config '#{queue_name}'")

      # path need to be specified
      raise QueueManagerException.new("[QueueManager] There is now path specified for queue '#{queue_name}'", caller) if queue_config["path"].nil?
      path = queue_config["path"]
      queue_config.delete "path"

      # set max size parameter -- this parameter is optional
      max_size = str_bytes(queue_config["max-size"])
      max_size = INFINITE if max_size.nil? || max_size <= 0
      queue_config.delete "max-size"

      # set max messages parameter -- this parameter is optional
      max_messages = queue_config["max-messages"].to_i
      max_messages = INFINITE if max_messages.nil? || max_messages <= 0
      queue_config.delete "max-messages"

      # set class parameter -- this parameter is optional
      default_class = queue_config["class"]
      default_class = eval(default_class) unless default_class.nil?
      queue_config.delete "class"

      if default_class.nil?
        queue = create_queue(path, max_messages, max_size)
      else
        queue = create_queue(path, max_messages, max_size, default_class)
      end

      if queue_config.size > 0
        @log.debug("[QueueManager] Configure addional parameters for queue '#{queue_name}'; parameter: #{queue_config.inspect}")
        for parameter in queue_config.keys
          method_name = parameter.gsub("-", "_")
          queue.send(method_name + "=", queue_config[parameter])
        end
      end
    end
    
  private
    # retuns count of bytes to a expression with kb, mb or gb
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
    
    # create the queues that are defined in the configuration
    def setup_queue_manager
      @log.info("[QueueManager] Create defined queues (#{@config["defined-queues"].size})")
      for defined_queue in @config["defined-queues"]
        create_queue_from_config(defined_queue[0], defined_queue[1])
      end
    end
  end
end