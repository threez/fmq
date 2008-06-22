require File.dirname(__FILE__) + '/test_helper.rb'

class TestFreeMessageQueue < Test::Unit::TestCase
  TEST_URL = "http://localhost:5884/fmq_test/test1"
  TEST_REQUEST = 'X' * 1200 # 1.2 KB
  
  def setup
    @queue = FreeMessageQueue::ClientQueue.new(TEST_URL)
  end

  def test_post_and_get_message
    5.times do |t|
      @queue.put(TEST_REQUEST + t.to_s)
    end
    
    assert_equal 5, @queue.size
    assert_equal TEST_REQUEST.size * 5 + 5, @queue.bytes
    
    5.times do |t|
      assert_equal TEST_REQUEST + t.to_s, @queue.poll()
    end
    
    assert_equal 0, @queue.size
    assert_equal 0, @queue.bytes
  end
end
