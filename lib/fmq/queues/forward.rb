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
  # This queue returns sends one message to several queues at a time.
  # 
  # configuration sample:
  #  queue-manager:
  #    auto-create-queues: true
  #    defined-queues:
  #      path: /fmq_test/forward_to_1_and_2
  #      class: FreeMessageQueue::ForwardQueue
  #      forward_to: /fmq_test/test1 /fmq_test/test2
  #
  # *NOTE* the poll method is not implemented in this queue. It is a put only queue.
  class ForwardQueue < BaseQueue
    
    def initialize(manager)
      super(manager)
      @forwards = []
    end
    
    # put the message from this queue to the queues
    # that are specified in the <em>forward-to</em> configuration option.
    def put(message)
      for forward in @forwards do
        @manager.put(forward, message.clone)
      end
    end
    
    # *CONFIGURATION* *OPTION
    # you can add as may queues as you want
    # but seperate them with a space char
    def forward_to=(urls)
      @forwards = urls
    end
  end
end
