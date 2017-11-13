class Chorg::MainRunner < Chorg::Runner
  include Chorg::Runner::Main
  include Job::SS::Binding::Task

  self.task_class = Chorg::Task
end
