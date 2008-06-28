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
require 'net/http'

module FreeMessageQueue
  # Here you can find the client side api for the free message queue.
  # This api is build using the net/http facilitys
  #
  # Some sample usage of the client api:
  #
  #  require "fmq"
  #  
  #  # queue adress
  #  QA = "http://localhost/webserver_agent/messages"
  #  queue = FreeMessageQueue::ClientQueue.new(QA)
  #  
  #  # pick one message
  #  message = queue.poll()
  #  puts " == URGENT MESSSAGE == " if message.option["Priority"] == "high"
  #  puts message.payload
  #  
  #  # put an urgent message on the queue e.g.in yaml
  #  payload = "message:
  #    title: server don't answer a ping request
  #    date_time: 2008-06-01 20:19:28
  #    server: 10.10.30.62
  #  "
  #  
  #  message = FreeMessageQueue::Message.new(payload, "application/yaml")
  #  queue.put(message)
  #
  class ClientQueue
    # create a connection to a queue (by url)
    def initialize(url)
      @url = URI.parse(url)
    end

    # this returns one message from the queue as a string
    def poll()
      res = Net::HTTP.start(@url.host, @url.port) do |http|
        http.get(@url.path)
      end
      
      message = Message.new(res.body, res["CONTENT-TYPE"])
      
      res.each_key do |option_name|
        if option_name.upcase.match(/MESSAGE_([a-zA-Z][a-zA-Z0-9_\-]*)/)
          message.option[$1] = res[option_name]
        end
      end
      
      return message
    end
    
    alias get poll
    
    # this puts one message to the queue
    def put(message)
      header = {}
      header["CONTENT-TYPE"] = message.content_type
      
      # send all options of the message back to the client
      if message.respond_to?(:option) && message.option.size > 0
        for option_name in message.option.keys
          header["MESSAGE_#{option_name}"] = message.option[option_name].to_s
        end
      end
      
      Net::HTTP.start(@url.host, @url.port) do |http|
        http.post(@url.path, message.payload, header)
      end
    end
    
    alias post put
    
    # return the size (number of messages) of the queue
    def size
      head["QUEUE_SIZE"].to_i
    end
    
    # return the size of the queue in bytes
    def bytes
      head["QUEUE_BYTES"].to_i
    end
  protected
    # do a head request to get the state of the queue
    def head()
      res = Net::HTTP.start(@url.host, @url.port) do |http|
        http.head(@url.path)
      end
    end
  end
end