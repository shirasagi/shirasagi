ActiveSupport::Notifications.subscribe('deliver.action_mailer') do |*args|
  begin
    event = ActiveSupport::Notifications::Event.new(*args)
    ::Sys::MailLog.add_from_event(event)
  rescue
    # suppress any errors
  end
end

ActionMailer::Base.include SS::Mailer::Rescuable
