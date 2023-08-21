RSpec.configuration.before(:example) do
  clear_enqueued_jobs
  clear_performed_jobs
end

RSpec.configuration.after(:example) do
end
