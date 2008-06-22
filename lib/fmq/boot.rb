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
require 'yaml' 
require 'logger'
require 'fileutils'

require File.dirname(__FILE__) + '/version'
require File.dirname(__FILE__) + '/queue_manager'
require File.dirname(__FILE__) + '/mongrel_server'

module FreeMessageQueue
  SERVER_HEADER = "FMQ/#{FreeMessageQueue::VERSION::STRING} (#{RUBY_PLATFORM}) Ruby/#{RUBY_VERSION}"
  
  def self.logger
    $FMQ_GLOBAL_LOGGER
  end
  
  def self.create_logger(log_to = STDOUT)
    $FMQ_GLOBAL_LOGGER ||= Logger.new(log_to)
  end
  
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
  
  class Configuration
    def initialize(file_path)
      # open and read file
      f = open(file_path, "r")
      data = f.read
      f.close
      @config = YAML.load( data )
      
      # set log level
      FreeMessageQueue.set_log_level(server["log-level"])
      
      # debug the configuration
      FreeMessageQueue.logger.debug("[Configuration] Server: " + YAML.dump(server))
      FreeMessageQueue.logger.debug("[Configuration] QueueManager: " + YAML.dump(queue_manager))
    end
    
    def server
      @config["server"]
    end
    
    def queue_manager
      @config["queue-manager"]
    end
  end
  
  class Boot
    def self.start_server
      # create logger and setup log level
      logger = FreeMessageQueue.create_logger
      conf = FreeMessageQueue::Configuration.new("config.yml")
      
      # create queue manager
      queue_manager = FreeMessageQueue::QueueManager.new(conf.queue_manager)
      
      # setup and run server
      logger.debug "[MongrelHandler] startup at #{conf.server["interface"]}:#{conf.server["port"]}"
      servsock = Mongrel::HttpServer.new(conf.server["interface"], conf.server["port"])
      servsock.register("/", FreeMessageQueue::MongrelHandler.new(queue_manager))
      servsock.run.join
    end
    
    def self.create_project(project_name)
      FileUtils.cp_r(File.dirname(__FILE__) + '/../../default-server', project_name)
    end
  end
end