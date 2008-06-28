require File.dirname(__FILE__) + '/test_helper.rb'

class TestFreeMessageQueue < Test::Unit::TestCase
  TEST_URL = "http://localhost:5884/fmq_test/test1"
  TEST_REQUEST = 'X' * 1200 # 1.2 KB
  
  def setup
    @queue = FreeMessageQueue::ClientQueue.new(TEST_URL)
  end

  def test_post_and_get_message
    5.times do |t|
      message = new_msg(TEST_REQUEST + t.to_s)
      message.option["ID"] = t
      message.option["application-name"] = "Test"
      @queue.put(message)
    end
    
    assert_equal 5, @queue.size
    assert_equal TEST_REQUEST.size * 5 + 5, @queue.bytes
    
    5.times do |t|
      message = @queue.poll()
      assert_equal TEST_REQUEST + t.to_s, message.payload
      assert_equal "text/plain", message.content_type
      assert_equal t, message.option["ID"].to_i
      assert_equal "Test", message.option["APPLICATION_NAME"]
    end
    
    assert_equal 0, @queue.size
    assert_equal 0, @queue.bytes
  end
end
