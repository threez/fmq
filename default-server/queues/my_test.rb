class MyTestQueue < FreeMessageQueue::BaseQueue
  def put(message)
    puts "INCOMMING: #{message.payload}"
  end
  
  def poll
    FreeMessageQueue::Message.new "Hello World", "text/plain" do |m|
      m.option["Time"] = Time.now
    end
  end
end