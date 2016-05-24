class SS::ApplicationJob < ::ApplicationJob
  include Job::SS::Core
  include Job::SS::Binding::Base
  include Job::SS::Loggable
end
