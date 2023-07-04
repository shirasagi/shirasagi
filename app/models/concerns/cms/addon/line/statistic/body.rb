module Cms::Addon
  module Line::Statistic::Body
    extend ActiveSupport::Concern
    extend SS::Addon

    def with_null_label(key)
      val = send(key)
      val.nil? ? t(:null_label) : val
    end

    def overview_delivered
      return if overview_unique_impression.nil?
      broadcast? ? statistics.dig("overview", "delivered") : member_count
    end

    def overview_unique_impression
      statistics.dig("overview", "uniqueImpression")
    end

    def overview_openrate
      return if overview_unique_impression.nil?
      return if overview_delivered.nil? || overview_delivered == 0
      ((overview_unique_impression.to_f / overview_delivered.to_f) * 100).round(2)
    end

    def overview_openrate_label
      return if overview_openrate.nil?
      "#{overview_openrate}%"
    end

    def overview_openrate_and_delivered_label
      return if overview_openrate.nil?
      "#{overview_unique_impression} / #{overview_delivered} (#{overview_openrate}%)"
    end

    def overview_unique_click
      statistics.dig("overview", "uniqueClick")
    end
  end
end
