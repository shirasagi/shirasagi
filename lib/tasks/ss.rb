module Tasks
  module SS
    class << self
      def invoke_task(name, *args)
        task = Rake.application[name]
        task.reenable
        task.invoke(*args)
      end
    end
  end
end
