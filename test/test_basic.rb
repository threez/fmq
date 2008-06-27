require File.dirname(__FILE__) + '/test_helper.rb'

# This is the default test to the message interface
class TestMessage < Test::Unit::TestCase
  def test_initialize
    msg = FreeMessageQueue::Message.new("....", "text/xml")
    msg.option['application'] = "fast_app"
    msg.option['expires'] = msg.created_at + (5 * 60) # 5 min after creation
    
    assert_equal 4, msg.bytes
    assert_equal 2, msg.option.size
    assert_equal "text/xml", msg.content_type
    assert_equal "fast_app", msg.option["application"]
  end
  
  def test_linking_of_messages
    msg_0 = FreeMessageQueue::Message.new("MyMac")
    msg_1 = FreeMessageQueue::Message.new("MyDesk")
    msg_2 = FreeMessageQueue::Message.new("MyRuby")
    
    msg_0.next = msg_1
    msg_1.next = msg_2
    
    assert_equal msg_2, msg_0.next.next
  end
end

class BaseQueue < Test::Unit::TestCase
  def test_initialize
    manager = "pseudo manager"
    queue = FreeMessageQueue::BaseQueue.new(manager)
    assert_equal 0, queue.size
    assert_equal 0, queue.bytes
    assert_equal manager, queue.manager
  end
end