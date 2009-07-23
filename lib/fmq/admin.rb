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
            @manager.setup_queue(request["path"], request["queue_class"]) do |q|
              q.max_messages = request["max_messages"].to_i
              q.max_size = str_bytes request["max_size"]
              request.params.each { |k,v|
                q.send("#{k[3..-1]}=", v) if k.match(/^qm_/)
              }
            end
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
      queue = @manager.queue(queue_name)

      "[\"%s\", %d, %d, %d, %d]" % [
        queue_name,
        queue.bytes,
        queue.max_size,
        queue.size,
        queue.max_messages,
      ]
    end

    # Retuns count of bytes to a expression with kb, mb or gb
    # e.g 10kb will return 10240
    def str_bytes(str)
      case str
        when /([0-9]+)kb/i
          $1.to_i.kb
        when /([0-9]+)mb/i
          $1.to_i.mb
        when /([0-9]+)gb/i
          $1.to_i.gb
        else
          BaseQueue::INFINITE
      end
    end
  end
end

