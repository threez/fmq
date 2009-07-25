require File.dirname(__FILE__) + '/helper.rb'

# This is the default test to the message interface
class TestLinkedQueue < Test::Unit::TestCase
  include FifoQueueTests
  
  def setup
    manager = nil # the manager is not needed in this test
    @queue = FreeMessageQueue::LinkedQueue.new(manager)
  end
end
