module SS::Mailer::Rescuable
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :rescue_deliver
  end

  def rescue_deliver(e)
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end
end
