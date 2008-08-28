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
require File.dirname(__FILE__) + '/syncronized'

module FreeMessageQueue
  # This queue is an approach to the issue that you want to have
  # multiple threads at one queue at a time. Currently this is not
  # considered to be a stable queue. Just use it for experimental things.
  #
  #  queue_manager = FreeMessageQueue::QueueManager.new(true) do
  #    setup_queue "/fmq_test/test1", FreeMessageQueue::LoadBalancedQueue do |q|
  #      q.forward_to = ["/fmq_test/test1", "/fmq_test/test2"]
  #    end
  #  end
  class LoadBalancedQueue    
    # QueueManager refrence
    attr_accessor :manager
    
    def initialize(manager, queue_count = 5)
      @manager = manager
      @queues = []
      queue_count.times do
        @queues << SyncronizedQueue.new(manager)
      end
      @poll_queue = @put_queue = 0
      @semaphore = Mutex.new
    end
    
    # delete all messages in all queues
    def clear
      @queues.each { |q| q.clear }
    end
    
    # size of the queue is sum of size of all load balanced queues
    def size
      size = 0
      @queues.each { |q| size += q.size }
      return size 
    end
    
    # size of queue in bytes
    def bytes
      tmp_bytes = 0
      @queues.each { |q| tmp_bytes += q.bytes }
      return tmp_bytes
    end
    
    # Return one message from one of the queues
    def poll
      @queues[next_poll_index].poll
    end
    
    # Put an item to one of the queues
    def put(message)
      @queues[next_put_index].put(message)
    end
    
    # queue has infinite count
    def max_messages
      BaseQueue::INFINITE
    end 
    
    # queue has infinite messages
    def max_size
      BaseQueue::INFINITE
    end
    
  private
    
    # next index acts like 'round robin'
    def next_poll_index
      @semaphore.synchronize {
        # continue at begin if end was reached
          pq = (@poll_queue + 1 == @queues.size) ? 0 : @poll_queue + 1
        
        # if current queue is emtpy use other instead if there are
        # some items left but try just 10 times
        i = 0
        while @queues[pq].size == 0 && self.size > 0 && i < 10
          pq = (@poll_queue + 1 == @queues.size) ? 0 : @poll_queue + 1
          i += 1
        end
        
        @poll_queue = pq # return index and save for next use
      }
    end
    
    # next index acts like 'round robin'
    def next_put_index
      @semaphore.synchronize {
        @put_queue = (@put_queue + 1 == @queues.size) ? 0 : @put_queue + 1
      }
    end
  end
end
