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
require 'yaml' 
require 'logger'
require 'fileutils'

require File.dirname(__FILE__) + '/version'
require File.dirname(__FILE__) + '/queue_manager'
require File.dirname(__FILE__) + '/mongrel_server'

module FreeMessageQueue
  # This is the standard server header that will be used by mongel and other web servers
  SERVER_HEADER = "FMQ/#{FreeMessageQueue::VERSION::STRING} (#{RUBY_PLATFORM}) Ruby/#{RUBY_VERSION}"
  
  # This method returns the ruby logger instance for the
  # free message queue, so that it is simple to access
  # the logger from somewhere in the project 
  def self.logger
    $FMQ_GLOBAL_LOGGER
  end
  
  # This method creates the logger instance once (even if it is called twice).
  def self.create_logger(log_to = STDOUT)
    $FMQ_GLOBAL_LOGGER ||= Logger.new(log_to)
  end
  
  # This method sets the log level of the fmq logger
  # the level must be a string (either downcase or upcase)
  # that contains one of the following levels:
  # * FATAL => Server side errors
  # * ERROR => Server side error backtraces
  # * WARN  => Client side errors
  # * INFO  => Setup information (config stuff etc.)
  # * DEBUG => All operations of the queue manager and others
  def self.set_log_level(level)
    case level
      when /fatal/i
        FreeMessageQueue.logger.level = Logger::FATAL
      when /error/i
        FreeMessageQueue.logger.level = Logger::ERROR
      when /warn/i
        FreeMessageQueue.logger.level = Logger::WARN
      when /info/i
        FreeMessageQueue.logger.level = Logger::INFO
      when /debug/i
        FreeMessageQueue.logger.level = Logger::DEBUG
    end
    FreeMessageQueue.logger.debug "[Logger] set log level to #{level}"
  end
  
  # The class implements a simple interface to the configuration file
  # and creates and setup the logger instance
  class Configuration
    # the yaml config file from <em>file_path</em> will be read and 
    # parsed. After parsing the global free message queue logger is
    # created and setup vor further use
    def initialize(file_path)
      # open and read file
      f = open(file_path, "r")
      data = f.read
      f.close
      @config = YAML.load( data )
      
      # create logger and setup log level
      @log = FreeMessageQueue.create_logger
      FreeMessageQueue.set_log_level(server["log-level"])
      
      # debug the configuration
      @log.debug("[Configuration] Server: " + YAML.dump(server))
      @log.debug("[Configuration] QueueManager: " + YAML.dump(queue_manager))
    end
    
    # the configuration for the server (MongrelHandler, ...)
    def server
      @config["server"]
    end
    
    # the configuration for the queue manager
    def queue_manager
      @config["queue-manager"]
    end
  end
  
  # Boot deals with the tasks to create up a project and start the server etc.
  class Boot
    # The configuration file <em>config.yml</em> must be in the same directory.
    # It is the starting point for booting the server.
    # After reading the configuration the QueueManager and HttpServer (MongrelHandler)
    # will be created and start listening.
    # This method will stop when the server goes down otherwise it will run infinitely
    def self.start_server
      conf = FreeMessageQueue::Configuration.new("config.yml")
      logger = FreeMessageQueue.logger
      
      # create queue manager
      queue_manager = FreeMessageQueue::QueueManager.new(conf.queue_manager)
      
      # setup and run server
      logger.debug "[MongrelHandler] startup at #{conf.server["interface"]}:#{conf.server["port"]}"
      servsock = Mongrel::HttpServer.new(conf.server["interface"], conf.server["port"])
      servsock.register("/", FreeMessageQueue::MongrelHandler.new(queue_manager))
      servsock.run.join
    end
    
    # This message will copy the <em>default-server</em> project files
    # to the passed (<em>project_name</em>) location.
    # The <em>default-server</em> contains some basic and sample stuff
    # so that the free message queue can be used as fast as possible. Including:
    # * The Admin UI (Ajax Interface) => so that you can make changes
    # * The default configuration => with some sample queues
    # * A custom queue implementation => to basically show how to create my own queues
    def self.create_project(project_name)
      FileUtils.cp_r(File.dirname(__FILE__) + '/../../default-server', project_name)
    end
  end
end