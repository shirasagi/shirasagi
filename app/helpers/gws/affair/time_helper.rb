module Gws::Affair::TimeHelper
  extend ActiveSupport::Concern

  def format_minute(minute)
    (minute.to_i > 0) ? "#{minute / 60}:#{format("%02d", (minute % 60))}" : "--:--"
  end

  def threshold_hour
    SS.config.gws.affair.dig("overtime", "aggregate", "threshold_hour")
  end
end
