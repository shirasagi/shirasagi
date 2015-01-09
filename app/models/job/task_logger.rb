require 'logger'

class Job::TaskLogger < ::Logger
  FLUSH_INTERVAL = 10.seconds

  def initialize(task = nil)
    @device = TaskLogDevice.new
    super(@device)
    @device.task = task
  end

  def task
    @device.task
  end

  def task=(task)
    @device.task = task
  end

  class TaskLogDevice
    attr_accessor :task

    def write(message)
      if task
        task.logs << message.chomp
        elapsed = Time.now - task.updated
        task.save if elapsed > FLUSH_INTERVAL
      end
    end

    # do not remove close method
    def close
    end
  end
end
