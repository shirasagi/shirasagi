namespace :job do
  task run: [:environment] do
    ::Tasks::Job.run
  end
end
