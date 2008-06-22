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
require 'ostruct'

module FreeMessageQueue
  class AdminQueue
    attr_accessor :manager
    
    def initialize()
      super
      @filter_queues = []
    end
  
    def poll()
      item = OpenStruct.new

      queues_code = []
      manager.queues.each do |queue_name|
        # skip if it is filterd
        next if filtered? queue_name
        
        # add a new entry to the array
        queues_code << queue_to_json(queue_name)
      end
      
      item.data = "[%s]" % queues_code.join(",")
      item
    end
    
    def put(data)
      if data.match(/_method=delete&path=(.*)/)
        # delete queue
        manager.delete_queue($1)
      elsif data.match(/_method=create&data=(.*)/)
        # create queue
        conf = eval($1.gsub(":", "=>").gsub("null", "-1"))
        manager.create_queue_from_config("dynamic-created-queue", conf)
      end
    end
    
    def size
      1 # there is always a message in the queue
    end
    
    def filter=(str)
      @filter_queues = str.split " "
    end
    
  private
  
    # check if the system queue should filter the queue
    def filtered? (name)
      skip = false
      for filter in @filter_queues
        skip = true if name[0...filter.size] == filter
      end
      skip
    end
  
    def queue_to_json(queue_name)
      constraints = manager.queue_constraints(queue_name)
    
      "[\"%s\", %d, %d, %d, %d]" % [
        queue_name,
        manager.queue(queue_name).bytes,
        constraints[:max_size],
        manager.queue(queue_name).size,
        constraints[:max_messages],
      ]
    end
  end
end