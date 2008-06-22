require "ostruct"

class MyTestQueue
  attr_accessor :manager
  attr_reader :bytes, :size
  
  def initialize
    @bytes = @size = 1
  end
  
  def put(data)
    puts "NEW MESSAGE"
  end
  
  def poll
    item = OpenStruct.new
    item.data = "Hello World"
    item
  end
end