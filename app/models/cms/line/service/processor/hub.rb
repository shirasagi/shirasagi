class Cms::Line::Service::Processor::Hub < Cms::Line::Service::Processor::Base
  def call
    return if service.hooks.blank?

    delegated = false
    events.each do |event|
      next if delegated

      user_id = channel_user_id(event)
      next if user_id.blank?
      next if richmenu_switched?(event)

      Cms::Line::EventSession.lock(site, user_id) do |event_session|
        begin
          self.event_session = event_session

          # default mode
          if event_session.hook.nil?
            event_session.hook = service.hooks.first
            event_session.update
          end

          # switch mode
          switched = false
          service.hooks.each do |hook|
            if hook.switch_hook(self, event)
              switched = true
              break
            end
          end
          next if switched

          # service expired?
          if service.expired_text.present? && service_expired?
            if event["type"] == "message"
              client.reply_message(event["replyToken"], {
                type: "text",
                text: service.expired_text
              })
            end
            raise Cms::Line::EventSession::ServiceExpiredError
          end

          # delegate event
          service.hooks.each do |hook|
            if hook.delegate(self, event)
              delegated = true
              break
            end
          end
        ensure
          self.event_session = nil
        end
      end
    end
  end

  def service_expired?
    return false unless event_session
    return false unless event_session.locked_at
    Time.zone.now >= event_session.locked_at + service.expired_minutes.minutes
  end
end
