class Gws::Affair2::Aggregation::Downloader::Base
  #extend SS::Translation
  include ActiveModel::Model

  attr_accessor :items, :unit

  def initialize(items, unit:)
    @items = items
    @unit = unit
  end

  def t_agg(key, opts = {})
    v = I18n.t("gws/affair2.aggregation.#{unit}.#{key}", **opts)
    return v if !v.is_a?(Array)
    return v[0] if v.size <= 1
    "#{v[0]}/#{v.drop(1).join}"
  end

  def monthly_threshold
    SS.config.affair2.overtime["monthly_threshold"]
  end

  def monthly_threshold_hour
    monthly_threshold / 60
  end
end
