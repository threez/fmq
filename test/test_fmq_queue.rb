require File.dirname(__FILE__) + '/test_helper.rb'

class TestFreeMessageQueue < Test::Unit::TestCase
  def setup
    #@queue = FreeMessageQueue::LinkedQueue.new
    @queue = FreeMessageQueue::SyncronizedQueue.new
  end
  
  def test_basic_get_poll
  	assert_nil @queue.poll
	  assert_equal 0, @queue.size
	  assert @queue.put(nil) == false
	  assert_nil @queue.poll
	  td_1 = "asdasd"
	  assert @queue.put(td_1)
	  assert_equal 1, @queue.size
	  assert_equal td_1, @queue.poll.data
  end
  
  def test_n_items
    n = 20
    byte_size = 0
    n.times { |t| byte_size += t.size }
    
	  assert_equal 0, @queue.bytes
	  assert_nil @queue.poll
	  n.times do |i|
	    assert @queue.put(i)
	  end
	  assert_equal byte_size, @queue.bytes
	  assert_equal n, @queue.size
	  n.times do |i|
	    assert_equal i, @queue.poll.data
	  end
	  assert_equal 0, @queue.bytes
	  assert_nil @queue.poll
  end
  
  def test_queue_bytes
    @queue.put("XX" * 40)
    @queue.put("X" * 40)
    @queue.put("XX888" * 40)
    assert_equal 2*40+40+5*40, @queue.bytes
    @queue.clear
    assert_equal 0, @queue.bytes
  end
end
