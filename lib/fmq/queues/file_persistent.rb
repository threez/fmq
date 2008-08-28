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
      messages = Dir[@folder_path + "/*.msg"].sort
      first_file = messages.first
      
      msg_bin = File.open(first_file, "rb") { |f| f.read }
      remove_message(Marshal.load(msg_bin))
    end
    
    # add one message to the queue (will be saved in file system)
    def put(message)
      return false if message.nil?
      
      add_message(message) # check constraints and update stats
      
      msg_bin = Marshal.dump(msg)
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
  end
end
