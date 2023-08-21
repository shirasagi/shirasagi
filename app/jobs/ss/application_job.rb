class SS::ApplicationJob < ::ApplicationJob
  include Job::SS::Core
  include Job::SS::Binding::Base
  include Job::SS::Loggable

  class << self
    def ss_app_type
      :sys
    end
  end
end
