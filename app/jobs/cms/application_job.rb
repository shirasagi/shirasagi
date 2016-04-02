class Cms::ApplicationJob < ::ApplicationJob
  include Job::Cms::Core
  include Job::Cms::Binding::Base
end
