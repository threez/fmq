require File.dirname(__FILE__) + '/helper.rb'

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
  def setup
    @manager = FreeMessageQueue::QueueManager.new() do 
      setup_queue "/dummy1"
      setup_queue "/dummy2" do |q|
        q.max_messages = 100
        q.max_size = 100.kb
      end
      setup_queue "/dummy3" do |q|
        q.max_size = 0
        q.max_messages = -10
      end
    end
    
    @queue1 = @manager.queue "/dummy1"
    @queue2 = @manager.queue "/dummy2"
    @queue3 = @manager.queue "/dummy3"
  end
  
  def test_creating
    # check first queue
    assert_equal 0, @queue1.size
    assert_equal 0, @queue1.bytes
    assert_equal FreeMessageQueue::BaseQueue::INFINITE, @queue1.max_messages
    assert_equal FreeMessageQueue::BaseQueue::INFINITE, @queue1.max_size
    
    # check 2. queue
    assert_equal 0, @queue2.size
    assert_equal 0, @queue2.bytes
    assert_equal 100, @queue2.max_messages
    assert_equal 100 * 1024, @queue2.max_size
    
    # check 3. queue
    assert_equal 0, @queue3.size
    assert_equal 0, @queue3.bytes
    assert_equal FreeMessageQueue::BaseQueue::INFINITE, @queue3.max_messages
    assert_equal FreeMessageQueue::BaseQueue::INFINITE, @queue3.max_size
    
    assert_equal @manager, @queue1.manager
  end
  
  def test_constraint_max_messages
    100.times do |v|
      @queue2.put(new_msg("test"))
    end
    
    assert_raise(FreeMessageQueue::QueueException) do
      @queue2.put(new_msg("test"))
    end
  end
  
  def test_constraint_max_size
    11.times do |v|
      @queue2.put(new_msg("X" * 9.kb))
    end
    
    assert_raise(FreeMessageQueue::QueueException) do
      @queue2.put(new_msg("X" * 10.kb))
    end
  end
end
