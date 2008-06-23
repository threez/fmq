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
require 'ostruct'

module FreeMessageQueue
  # This queue is dedicated to the AJAX based admin interface.
  #
  # configuration sample:
  #  queue-manager:
  #    auto-create-queues: true
  #    defined-queues:
  #      admin-page-backend:
  #      path: /admin/queue
  #      class: FreeMessageQueue::AdminQueue
  #      filter: /admin
  class AdminQueue
    # QueueManager refrence
    attr_accessor :manager
    
    # Bytes size is -1. Size is allways 1 message
    attr_reader :bytes, :size
    
    def initialize()
      super
      @bytes = -1
      @size = 1
      @filter_queues = []
    end
  
    # returns an json list of visible queues
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
    
    # can be either used to *create* or *delete* a queue
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
    
    # *CONFIGURATION* *OPTION*
    # sets the paths that should be filterd out, seperate them with space char
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
  
    # converts the data of one queue to json format
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