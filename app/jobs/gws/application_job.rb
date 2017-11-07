class Gws::ApplicationJob < ::ApplicationJob
  include Job::SS::Core
  include Job::Gws::Binding::Base
  include Job::Gws::Loggable

  around_perform do |job, block|
    begin
      block.call
    rescue => e
      Gws::History.error!(
        :job, user, site,
        job: self.class.name.underscore, action: 'perform', message: "#{e.class} (#{e.message})"
      ) rescue nil
      raise e
    end
  end
end
