require File.dirname(__FILE__) + '/test_helper.rb'

# This is the tests the queue manager interface
class TestQueueManager < Test::Unit::TestCase
  DEFAULT_QUEUE_NAME = "/fmq_test/test1"
  
  def setup
    FreeMessageQueue.log_level "fatal"

    @queue_manager = FreeMessageQueue::QueueManager.new()
    
    @queue_manager.setup do |qm|
      qm.auto_create_queues = false
      
      qm.setup_queue DEFAULT_QUEUE_NAME do |q|
        q.max_messages = 100
        q.max_size = 100.mb
      end
    end
  end
  
  def test_config
    # check that the simple config will work
    FreeMessageQueue::QueueManager.new()
    @queue_manager.setup do |qm|
      qm.auto_create_queues = false
    end
  end
  
  def test_poll_and_get
    10.times do
      @queue_manager.put(DEFAULT_QUEUE_NAME, new_msg("XXX" * 20))
    end
    assert_equal 10, @queue_manager.queue(DEFAULT_QUEUE_NAME).size
    i = 0
    while message = @queue_manager.poll(DEFAULT_QUEUE_NAME)
      i += 1
    end
    assert_equal 10, i
    assert_equal 0, @queue_manager.queue(DEFAULT_QUEUE_NAME).size
    
    # should raise a exception because of the maximum messages limitation
    i = 0
    assert_raise(FreeMessageQueue::QueueException) {
      101.times do
        @queue_manager.put(DEFAULT_QUEUE_NAME, new_msg("XXX" * 20))
          i += 1
      end
    }
    @queue_manager.queue(DEFAULT_QUEUE_NAME).clear
    assert_equal 0, @queue_manager.queue(DEFAULT_QUEUE_NAME).size
    assert i = 100
    
    # should raise a exception because of the maximum byte size limitation
    i = 0
    two_mb_message = new_msg("X" * 1024 * 1024 * 2)
    assert_raise(FreeMessageQueue::QueueException) {
      101.times do
        @queue_manager.put(DEFAULT_QUEUE_NAME, two_mb_message) 
        i += 1
      end
    }
    assert i = 50
  end
  
  def test_creating_and_deleting
    url = "/XX123"
    @queue_manager.setup_queue url
    @queue_manager.put(url, new_msg("X_X_X_X_X_X"))
    assert_equal "X_X_X_X_X_X", @queue_manager.poll(url).payload
    @queue_manager.delete_queue(url)
    
    # auto queue creation is off
    assert_raise(FreeMessageQueue::QueueManagerException) {
      @queue_manager.put(url, new_msg("Test"))
    }
  end
end