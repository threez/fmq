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
require "fileutils"

module FreeMessageQueue
  # This a FIFO queue that stores messages in the file system
  # 
  #  queue_manager = FreeMessageQueue::QueueManager.new(true) do
  #    setup_queue "/mail_box/threez", FreeMessageQueue::FilePersistentQueue do |q|
  #      q.folder = "./tmp/mail_box/threez"
  #      q.max_messages = 10000
  #    end
  #  end
  #
  # *NOTE* the put method is not implemented in this queue. It is a poll only queue.
  class FilePersistentQueue < BaseQueue
    # Return the 
    def poll()
      check_folder_name
      messages = all_messages.sort!
      return nil if messages.size == 0
      
      msg_bin = File.open(messages.first, "rb") { |f| f.read }
      FileUtils.rm messages.first
      remove_message(Marshal.load(msg_bin))
    end
    
    # add one message to the queue (will be saved in file system)
    def put(message)
      check_folder_name
      return false if message.nil?
      
      add_message(message) # check constraints and update stats
      
      msg_bin = Marshal.dump(message)
      File.open(@folder_path + "/#{Time.now.to_f}.msg", "wb") do |f|
        f.write msg_bin
      end
      return true
    end
    
    # *CONFIGURATION* *OPTION*
    # sets the path to the folder that holds all messages, this will
    # create the folder if it doesn't exist
    def folder=(path)
      FileUtils.mkdir_p path unless File.exist? path
      @folder_path = path
    end
  
    # remove all items from the queue
    def clear
      FileUtils.rm all_messages
      @size = 0
      @bytes = 0
    end
    
  private
    
    # returns an array with all paths to queue messages
    def all_messages
      Dir[@folder_path + "/*.msg"]
    end
    
    # raise an exceptin if the folder name is not set
    def check_folder_name
      raise QueueException.new("[FilePersistentQueue] The folder_path need to be specified", caller) if @folder_path.nil?
    end 
  end
end
