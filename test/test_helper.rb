require 'test/unit'
require File.dirname(__FILE__) + '/../lib/fmq'

def new_msg(payload)
  FreeMessageQueue::Message.new(payload)
end