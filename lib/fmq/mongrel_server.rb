#!/usr/bin/env ruby -wKU
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
  require "mongrel"
rescue LoadError
  require "rubygems"
  require "mongrel"
end

module FreeMessageQueue
  # This implements the MongrelServlet that serves free message queue
  # in a mongrel enviroment
  class MongrelHandler < Mongrel::HttpHandler
    # When creationg a mongrel handler you have to pass the <em>queue_manager</em>
    # that should be distributed by mongrel
    def initialize(queue_manager)
      @queue_manager = queue_manager
      @log = FreeMessageQueue.logger
    end
  
    # Process incoming request and send them to the right sub processing method like <em>process_get</em>
    def process(request, response)
      queue_path = request.params["REQUEST_PATH"]
      method = request.params["REQUEST_METHOD"]
      @log.debug("[MongrelHandler] Incomming request for #{queue_path} [#{method}] (#{request.params["REMOTE_ADDR"]})")
      @log.debug("[MongrelHandler] Request data: #{YAML.dump(request.params)})")
      
      begin
        # process supported features
        if method.match(/^(GET|POST|HEAD|DELETE)$/) then
          self.send("process_" + method.downcase, request, response, queue_path)
        else
          client_exception(request, response, queue_path, 
            ArgumentError.new("[MongrelHandler] Method is not supported '#{method}'"))
        end
      rescue QueueManagerException => ex
        client_exception(request, response, queue_path, ex)
      rescue => ex
        server_exception(request, response, queue_path, ex)
      end
    end
  
  protected
  
    # Returns an item from queue and sends it to the client.
    # If there is no item to fetch send an 204 (NoContent) and same as HEAD
    def process_get(request, response, queue_path)
      queue_item = @queue_manager.poll(queue_path)
      
      if queue_item then
        response.start(200) do |head,out|
          @log.debug("[MongrelHandler] Response to GET (200)")
          head["Content-Type"] = (queue_item.respond_to?(:content_type)) ? queue_item.content_type : "text/plain"
          head["Server"] = SERVER_HEADER
          head["Queue-Size"] = @queue_manager.queue_size(queue_path)
          if !queue_item.data.nil? && queue_item.data.size > 0
            @log.debug("[MongrelHandler] Response data: #{queue_item.data}")
            out.write(queue_item.data)
          end
        end
      else
        response.start(204) do |head,out|
          @log.debug("[MongrelHandler] Response to GET (204)")
          head["Server"] = SERVER_HEADER
          head["Queue-Size"] = 0
        end
      end
    end
    
    # Put new item to the queue and and return sam e as head action (HTTP 200)
    def process_post(request, response, queue_path)
      @log.debug("[MongrelHandler] Response to POST (200)")
      data = request.body.read
      @log.debug("[MongrelHandler] DATA: #{data}")
      @queue_manager.put(queue_path, data)
      
      response.start(200) do |head,out|
        head["Server"] = SERVER_HEADER
        head["Queue-Size"] = @queue_manager.queue_size(queue_path)
      end
    end
    
    # Just return server header and queue size (HTTP 200)
    def process_head(request, response, queue_path)
      @log.debug("[MongrelHandler] Response to HEAD (200)")
      
      response.start(200) do |head,out|
        head["Server"] = SERVER_HEADER
        head["Queue-Size"] = @queue_manager.queue_size(queue_path)
      end
    end
    
    # Delete the queue and return server header (HTTP 200)
    def process_delete(request, response, queue_path)
      @log.debug("[MongrelHandler] Response to DELETE (200)")
      @queue_manager.delete_queue(queue_path)

      response.start(200) do |head,out|
        head["Server"] = SERVER_HEADER
      end
    end
    
    # Inform the client that he did something wrong (HTTP 400).
    # HTTP-Header field Error contains information about the problem.
    # The client errorwill also be reported to warn level of logger.
    def client_exception(request, response, queue_path, ex)
      @log.warn("[MongrelHandler] Client error: #{ex}")
      response.start(400) do |head,out|
        head["Server"] = SERVER_HEADER
        head["Error"] = ex.message
      end
    end
    
    # Report server error (HTTP 500).
    # HTTP-Header field Error contains information about the problem.
    # The body of the response contains the full stack trace.
    # The error and stack trace will also be reported to logger.
    def server_exception(request, response, queue_path, ex)
      @log.fatal("[MongrelHandler] System error: #{ex}")
      for line in ex.backtrace
        @log.error line
      end
      
      response.start(500) do |head,out|
        head["Content-Type"] = "text/plain"
        head["Server"] = SERVER_HEADER
        head["Error"] = ex.message
        
        out.write(ex.message + "\r\n\r\n")
        for line in ex.backtrace
          out.write(line + "\r\n")
        end
      end
    end
  end
end