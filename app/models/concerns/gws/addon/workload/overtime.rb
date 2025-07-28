module Gws::Addon::Workload::Overtime
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    (1..12).each do |m|
      attr_accessor "in_month#{m}_hours", "in_month#{m}_minutes"

      field "month#{m}_minutes", type: Integer, default: 0
      permit_params "in_month#{m}_hours", "in_month#{m}_minutes"

      define_method("month#{m}_hours_label") do
        minutes = send("month#{m}_minutes")
        minutes = minutes_to_hf(minutes)
        ActiveSupport::NumberHelper.number_to_rounded(minutes, strip_insignificant_zeros: true)
      end
      define_method("month#{m}_label") do
        minutes = send("month#{m}_minutes")
        hour, min = minutes_to_hm(minutes)

        label = []
        label << "#{hour}#{I18n.t("ss.time")}" if hour > 0
        label << "#{min}#{I18n.t("datetime.prompts.minute")}"
        label << "(#{send("month#{m}_hours_label")}h)"
        label.join(" ")
      end
    end
    before_validation :set_minutes
  end

  def init_minutes
    (1..12).each do |m|
      hour, min = minutes_to_hm(send("month#{m}_minutes"))
      send("in_month#{m}_hours=", hour)
      send("in_month#{m}_minutes=", min)
    end
  end

  def minutes_to_hm(minutes)
    [minutes.to_i / 60, minutes.to_i % 60]
  end

  def minutes_to_hf(minutes)
    (minutes.to_f / 60).round(2)
  end

  private

  def set_minutes
    (1..12).each do |m|
      hours = send("in_month#{m}_hours")
      minutes = send("in_month#{m}_minutes")
      next if hours.nil? && minutes.nil?
      send("month#{m}_minutes=", ((hours.to_i * 60) + minutes.to_i))
    end
  end
end
