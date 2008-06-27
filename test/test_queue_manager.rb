require File.dirname(__FILE__) + '/test_helper.rb'

# This is the tests the queue manager interface
class TestQueueManager < Test::Unit::TestCase
  DEFAULT_QUEUE_NAME = "/fmq_test/test1"
  
  def setup
    FreeMessageQueue.create_logger
    FreeMessageQueue.set_log_level "fatal"
    
    @working_conf = {
      "auto-create-queues" => false,
      "defined-queues" => {
        "test-queue-1" => {
          "path" => DEFAULT_QUEUE_NAME,
          "max-messages" => 100,
          "max-size" => "100mb"
        }
      }
    }
    @queue_manager = FreeMessageQueue::QueueManager.new(@working_conf)
  end
  
  def test_config
    # check constraints
    constraints = { :max_messages => 100, :max_size => 104857600 }
    assert_equal constraints, @queue_manager.queue_constraints[DEFAULT_QUEUE_NAME]
    
    # the queue manager can't be created without config
    assert_raise(FreeMessageQueue::QueueManagerException) {
      FreeMessageQueue::QueueManager.new(nil)
    }
    
    # check that the simple config will work
    simple = {
      "auto-create-queues" => true,
      "defined-queues" => {}
    }
    FreeMessageQueue::QueueManager.new(simple)
  end
  
  def test_poll_and_get
    10.times do
      @queue_manager.put(DEFAULT_QUEUE_NAME, new_msg("XXX" * 20))
    end
    assert_equal 10, @queue_manager.queue_size(DEFAULT_QUEUE_NAME)
    i = 0
    while message = @queue_manager.poll(DEFAULT_QUEUE_NAME)
      i += 1
    end
    assert_equal 10, i
    assert_equal 0, @queue_manager.queue_size(DEFAULT_QUEUE_NAME)
    
    # should raise a exception because of the maximum messages limitation
    i = 0
    assert_raise(FreeMessageQueue::QueueManagerException) {
      101.times do
        @queue_manager.put(DEFAULT_QUEUE_NAME, new_msg("XXX" * 20))
          i += 1
      end
    }
    @queue_manager.queue[DEFAULT_QUEUE_NAME].clear
    assert_equal 0, @queue_manager.queue_size(DEFAULT_QUEUE_NAME)
    assert i = 100
    
    # should raise a exception because of the maximum byte size limitation
    i = 0
    two_mb_message = new_msg("X" * 1024 * 1024 * 2)
    assert_raise(FreeMessageQueue::QueueManagerException) {
      101.times do
        @queue_manager.put(DEFAULT_QUEUE_NAME, two_mb_message) 
        i += 1
      end
    }
    assert i = 50
  end
  
  def test_creating_and_deleting
    url = "/XX123"
    @queue_manager.create_queue(url)
    @queue_manager.put(url, new_msg("X_X_X_X_X_X"))
    assert_equal "X_X_X_X_X_X", @queue_manager.poll(url).payload
    @queue_manager.delete_queue(url)
    
    # auto queue creation is off
    assert_raise(FreeMessageQueue::QueueManagerException) {
      @queue_manager.put(url, new_msg("Test"))
    }
  end
end