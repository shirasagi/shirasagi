class Gws::Chorg::TestRunner < Gws::Chorg::Runner
  include Chorg::Runner::Test
  include Job::SS::Binding::Task

  self.task_class = Gws::Chorg::Task
end
