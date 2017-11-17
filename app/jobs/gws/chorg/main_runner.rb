class Gws::Chorg::MainRunner < Gws::Chorg::Runner
  include Chorg::Runner::Main
  include Job::SS::Binding::Task

  self.task_class = Gws::Chorg::Task
end
