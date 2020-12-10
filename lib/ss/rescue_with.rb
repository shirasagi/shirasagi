module SS::RescueWith
  extend ActiveSupport::Concern

  def rescue_with(exception_classes: [StandardError], ensure_p: nil)
    yield
  rescue *exception_classes => e
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    nil
  ensure
    ensure_p.call if ensure_p
  end
end
