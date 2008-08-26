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
begin
  require "rack"
rescue LoadError
  require "rubygems"
  require "rack"
end

module FreeMessageQueue
  # This class is dedicated to the AJAX based admin interface.
  class AdminInterface
    # rack response for bad requests
    WRONG_METHOD = [400, {"CONTENT-TYPE" => "text/plain", "ERROR" => "Wrong http Method"}, ""]
    
    # rack response for good requests
    OK = [200, {"CONTENT-TYPE" => "text/plain"}, ["ok"]]
    
    # create the admin interface for the passed QueueManager
    def initialize(queue_manager)
      @manager = queue_manager
      @log = FreeMessageQueue.logger
    end
  
    # handle all requests
    def call(env)
      begin
        request = Rack::Request.new(env)
        @log.debug "[AdminInterface] ENV: #{env.inspect}"
        
        if request.get? then
          @log.info "[AdminInterface] list queues"
          # ======= LIST QUEUES
          queues_code = []
          @manager.queues.each do |queue_name|
            queues_code << queue_to_json(queue_name)
          end
          
          return [200, {"CONTENT-TYPE" => "application/json"}, ["[%s]" % queues_code.join(","), ]]
        elsif request.post? then
          if request["_method"] == "delete" then
            # ======= DELETE QUEUE
            @log.info "[AdminInterface] delete queue"
            @manager.delete_queue(request["path"])
            return OK
          elsif request["_method"] == "create"
            # ======= CREATE QUEUE
            @log.info "[AdminInterface] create queue"
            @manager.create_queue(request["path"], 
              request["max_messages"].gsub("null", "-1").to_i, 
              request["max_size"].gsub("null", "-1").to_i)
            return OK
          else
            return WRONG_METHOD
          end
        else
          return WRONG_METHOD
        end
      rescue QueueManagerException => ex
        return [400, {"CONTENT-TYPE" => "text/plain", "ERROR" => ex.message}, [ex.message]]
      end
    end
    
  private
  
    # converts the data of one queue to json format
    def queue_to_json(queue_name)
      constraints = @manager.queue_constraints[queue_name]
    
      "[\"%s\", %d, %d, %d, %d]" % [
        queue_name,
        @manager.queue[queue_name].bytes,
        constraints[:max_size],
        @manager.queue[queue_name].size,
        constraints[:max_messages],
      ]
    end
  end
end

