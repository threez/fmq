require File.dirname(__FILE__) + '/test_helper.rb'
require "fileutils"

# This is the default test to the message interface
class TestFilePersistentQueue < Test::Unit::TestCase
  include FifoQueueTests
  
  def setup
    manager = nil # the manager is not needed in this test
    @queue = FreeMessageQueue::FilePersistentQueue.new(manager)
    @queue.folder = "/tmp/fmq/FilePersistentQueue/testqueue"
  end
  
  def teardown
    # remove the test data
    FileUtils.rm_rf "/tmp/fmq"
  end
end
