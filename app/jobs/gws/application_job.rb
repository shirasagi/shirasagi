class Gws::ApplicationJob < ::ApplicationJob
  include Job::SS::Core
  include Job::Gws::Binding::Base
  include Job::Gws::Loggable

  around_perform do |job, block|
    begin
      block.call
    rescue => e
      puts_history(:error, "#{e.class} (#{e.message})")
      raise e
    end
  end

  def puts_history(severity, message)
    Gws::History.write!(
      severity.to_sym, :job, user, site,
      job: self.class.name.underscore, action: 'perform', message: message
    ) rescue nil
  end
end
