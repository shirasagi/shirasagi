class Gws::ApplicationJob < ::ApplicationJob
  include Job::SS::Core
  include Job::Gws::Binding::Base
  include Job::Gws::Loggable
end
