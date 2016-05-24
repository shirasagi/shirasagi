class Cms::ApplicationJob < ::ApplicationJob
  include Job::Cms::Core
  include Job::Cms::Binding::Base
  include Job::Cms::Loggable
end
