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

module FreeMessageQueue
  # This queue distributes the polls and puts to different queues. It uses a round robin, so each queue
  # will be called in order every time. E.g. if you have three queues specified in the redirect_to
  # statement and use the poll method it will poll the first queue. If you poll the second time the RoundRobinQueue
  # will poll the second queue and if you poll the fourth time the RoundRobinQueue will again poll the first queue.
  #
  #  queue_manager = FreeMessageQueue::QueueManager.new(true) do
  #    setup_queue "/fmq_test/test1", FreeMessageQueue::RoundRobinQueue do |q|
  #      q.redirect_to ["/fmq_test/test1", "/fmq_test/test2"]
  #      # one can optionally configure what methods are allowed
  #      # by default it is [:put, :poll]
  #      q.allow :poll
  #    end
  #  end
  class RoundRobinQueue < BaseQueue
    def initialize(manager)
      super(manager)
      @allow = [:poll, :put]
      @queue_index = -1 # as starting point will be 0 later by using next_queue
    end

    def poll
      if allowed? :poll
        manager.poll(@redirect_to[next_queue])
      else
        raise QueueException.new("[RoundRobinQueue] you can't poll from this queue", caller)
      end
    end

    def put(message)
      if allowed? :put
        manager.put(@redirect_to[next_queue], message)
      else
        raise QueueException.new("[RoundRobinQueue] you can't put to this queue", caller)
      end
    end

    # *CONFIGURATION* *OPTION*
    # allow actions *:put* or *:poll*. You can pass and array for both (*[:poll, :put]*) or just one *:put*
    def allow(val)
      @allow = val
    end

    # *CONFIGURATION* *OPTION*
    # specifiy the queues that should be used (must be an array)
    def redirect_to(val)
      @redirect_to = val
    end

  private
  
    # returns the index of the next queue
    # (this is the round robin)
    def next_queue
      if @queue_index + 1 < @redirect_to.size
        @queue_index += 1
      else
        @queue_index = 0
      end
    end

    # is this method (put, poll) allowed
    def allowed? (method)
      if @allow.respond_to? :each
        @allow.include method
      else
        @allow == method
      end
    end
  end
end