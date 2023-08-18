class Cms::ApplicationJob < ::ApplicationJob
  include Job::Cms::Core
  include Job::Cms::Binding::Base
  include Job::Cms::Loggable

  class << self
    def ss_app_type
      :cms
    end
  end
end
