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
require 'logger'

require File.dirname(__FILE__) + '/version'
require File.dirname(__FILE__) + '/queue_manager'

module FreeMessageQueue
  # This is the standard server header that will be used by mongel and other web servers
  SERVER_HEADER = "FMQ/#{FreeMessageQueue::VERSION::STRING} (#{RUBY_PLATFORM}) Ruby/#{RUBY_VERSION}"
  
  # This method returns the ruby logger instance for the
  # free message queue, so that it is simple to access
  # the logger from somewhere in the project 
  def self.logger
    $FMQ_GLOBAL_LOGGER ||= create_logger
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
  def self.log_level(level)
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
  
  # Boot deals with the tasks to create up a project and start the server etc.
  class Boot    
    # This method will copy the <em>default-server</em> project files
    # to the passed (<em>project_name</em>) location.
    # The <em>default-server</em> contains some basic and sample stuff
    # so that the free message queue can be used as fast as possible. Including:
    # * The Admin UI (Ajax Interface) => so that you can make changes
    # * The default configuration => with some sample queues
    # * A custom queue implementation => to basically show how to create my own queues
    def self.create_project(project_name)
      require 'fileutils'
      FileUtils.cp_r(File.dirname(__FILE__) + '/../../default-server', project_name)
    end
  end
end
