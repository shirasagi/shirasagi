class Job::Service::Runner
  include SS::RescueWith

  def initialize
    @lock = Mutex.new
    @condition = ConditionVariable.new
    @stop = false
  end

  def run
    name = Job::Service.config.name
    Job::Service.advertise(name)

    rescue_with(ensure_p: ->{ Job::Service.unadvertise(name) }) do
      service_loop
    end
  end

  def shutdown
    @lock.synchronize do
      @stop = true
      @condition.signal
    end
  end

  private

  def service_loop
    return execute_loop if Job::Service.config.mode != 'service'

    wait = Job::Service.config.polling.interval || 5
    until @stop
      execute_loop

      @lock.synchronize do
        break if @stop
        @condition.wait(@lock, wait)
      end
    end
  end

  def execute_loop
    until @stop
      task = dequeue_task
      break unless task

      rescue_with(ensure_p: -> { task.destroy }) do
        task.execute
      end
    end
    nil
  end

  def dequeue_task
    Job::Service.config.polling.queues.each do |queue_name|
      task = Job::Task.dequeue(queue_name)
      return task if task
    end

    nil
  end
end
