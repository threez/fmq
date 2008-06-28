class MyTestQueue < FreeMessageQueue::BaseQueue
  def put(message)
    puts "INCOMMING: #{message.payload}"
  end
  
  def poll
    msg = FreeMessageQueue::Message.new "Hello World", "text/plain"
    msg.option["Time"] = Time.now
    msg
  end
end