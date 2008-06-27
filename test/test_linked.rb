require File.dirname(__FILE__) + '/test_helper.rb'

# This is the default test to the message interface
class TestLinkedQueue < Test::Unit::TestCase
  def setup
    manager = nil # the manager is not needed in this test
    @queue = FreeMessageQueue::LinkedQueue.new(manager)
  end
  
  def test_basic_get_poll
  	assert_nil @queue.poll
	  assert_equal 0, @queue.size
	  assert @queue.put(nil) == false
	  assert_nil @queue.poll
	  td_1 = new_msg("asdasd")
	  assert @queue.put(td_1)
	  assert_equal 1, @queue.size
	  assert_equal td_1.payload, @queue.poll.payload
  end
  
  def test_n_items
    n = 20
    byte_size = 0
    n.times { |t| byte_size += t.to_s.size }
    
	  assert_equal 0, @queue.bytes
	  assert_nil @queue.poll
	  n.times do |i|
	    assert @queue.put(new_msg(i.to_s))
	  end
	  assert_equal byte_size, @queue.bytes
	  assert_equal n, @queue.size
	  n.times do |i|
	    assert_equal i.to_s, @queue.poll.payload
	  end
	  assert_equal 0, @queue.bytes
	  assert_nil @queue.poll
  end
  
  def test_queue_bytes
    @queue.put(new_msg("XX" * 40))
    @queue.put(new_msg("X" * 40))
    @queue.put(new_msg("XX888" * 40))
    assert_equal 2*40+40+5*40, @queue.bytes
    @queue.clear
    assert_equal 0, @queue.bytes
  end
end