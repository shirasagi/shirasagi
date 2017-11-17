class Chorg::TestRunner < Chorg::Runner
  include Chorg::Runner::Test
  include Job::SS::Binding::Task

  self.task_class = Chorg::Task
end
