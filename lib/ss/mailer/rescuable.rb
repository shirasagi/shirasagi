module SS::Mailer::Rescuable
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |e|
      Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    end
  end
end
