== Creating custom queues:

Read this simple description on how to create a queue for your special purpose.
First of all, this template is where you start.
1. You have to create a class that is meanful and ends up with "Queue" (for naming convention) e.g. "MyTestQueue"
2. Name your file to the name of the queue. In this example we have the queue "MyTestQueue" 
   so the file will be "my_test.rb". Save your new file to the queue folder of your projects folder "queues/my_test.rb"
3. Change the queue implementation to something you like
   * every queue must have an <em>manager</em>.
   * this manager must be able to read <em>bytes</em> and <em>size</em>
   * the queue should have at least one of the <tt>put(data)</tt> or <tt>poll()</tt> methods defined
   * when implementing the poll queue the object you returning needs to have a <em>data</em> method.
     This examples uses OpenStruct for this purpose

  # FILE: my_project/queues/my_test.rb

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