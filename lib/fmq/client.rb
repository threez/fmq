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
  #  QA = "http://localhost/webserver_agent/urgent_messages"
  #  
  #  my_remote_queue = FreeMessageQueue::ClientQueue.new(QA)
  #  
  #  # pick one message
  #  msg = my_remote_queue.get()
  #  puts " == URGENT MESSSAGE == "
  #  puts msg
  #  
  #  # put an urgent message on the queue e.g.in yaml
  #  msg = "
  #    title: server don't answer a ping request
  #    date_time: 2008-06-01 20:19:28
  #    server: 10.10.30.62
  #  "
  #  
  #  my_remote_queue.put(msg)
  #
  class ClientQueue
    # create a connection to a queue (by url)
    def initialize(url)
      @url = url
    end

    # this returns one message from the queue as a string
    def poll()
      url = URI.parse(@url)
      req = Net::HTTP::Get.new(url.path)
      res = Net::HTTP.start(url.host, url.port) do |http|
        http.request(req)
      end
      res.body
    end
    
    alias get poll
    
    # this puts one message to the queue as a string
    def put(data)
      url = URI.parse(@url)
      res = Net::HTTP.start(url.host, url.port) do |http|
        http.post(url.path, data)
      end
    end
    
    alias post put
  end
end