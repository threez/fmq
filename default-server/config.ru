begin
  require File.dirname(__FILE__) + '/../lib/fmq'
rescue LoadError
  require "fmq"
end

# load all local queues (from project directory)
Dir.glob("queues/*.rb").each { |f| require f }

# setup log level of free message queue
FreeMessageQueue.log_level("info")

# =====================================================
#        create and configure the queue manager
# =====================================================
queue_manager = FreeMessageQueue::QueueManager.new()

queue_manager.setup do |qm|
  # if someone pushes to a queue that don't exists
  # the queue manager will create one for you if the option
  # <em>auto_create_queues</em> is <b>true</b>. This
  # is a useful option if you are in development,
  # the queue will be a FreeMessageQueue::SyncronizedQueue by default
  qm.auto_create_queues = true
  
  # =====================================================
  #      if you want some queues right from startup
  #        define there url and constraints here
  # =====================================================
  
  # the path to the queue e.g. /app1/myframe/test1
  # means http://localhost:5884/app1/myframe/test1
  # this parameter is not optional
  qm.setup_queue "/fmq_test/test1" do |q|
    # this defines the maximum count of messages that 
    # can be in the queue, if the queue is full every
    # new message will be rejected with a http error
    # this parameter is optional if you don't specify
    # a max value the queue size depends on your system
    q.max_messages = 1_000_000
    # this optional to and specifys the max content size
    # for all data of a queue
    # valid extensions are kb, mb, gb
    q.max_size = 10.kb
  end
  
  # if you want you can specify the class of the queue
  # this is interessting if you write your own queues
  qm.setup_queue "/fmq_test/test2", FreeMessageQueue::LoadBalancedQueue
  
  # if you have special queues include put them into the queues
  # folder and and use them (this MyTestQueue is places in queues/mytest.rb)
  qm.setup_queue "/fmq_test/test3", MyTestQueue
  
  # this is a forwarding queue wich forwards one message
  # to some other queues
  qm.setup_queue "/fmq_test/forward_to_1_and_2", FreeMessageQueue::ForwardQueue do |q|
    # you can add as may queues as you want
    # but seperate them with a space char
    q.forward_to = ["/fmq_test/test1", "/fmq_test/test2"]
  end
end

# =====================================================
#           setup the ajax admin interface
# =====================================================

# handle requests to remove, create, update queues
map "/admin/backend" do
  run FreeMessageQueue::AdminInterface.new(queue_manager)
end

# serve static files in admin-interface folder
map "/admin" do
  run Rack::File.new("./admin-interface")
end

# =====================================================
#      install the server for the queue maneger
# =====================================================

map "/" do
  run FreeMessageQueue::Server.new(queue_manager)
end
