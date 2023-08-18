module Cms::Addon::Line::DeliverPlan::Repeat
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    attr_accessor :repeat_type, :interval, :repeat_start, :repeat_end, :repeat_base, :wdays
    permit_params :repeat_type, :interval, :repeat_start, :repeat_end, :repeat_base, wdays: []

    before_validation :validate_repeat

    validates :repeat_start, presence: true, if: -> { repeat? }
    validates :repeat_end, presence: true, if: -> { repeat? }
    validates :repeat_type, inclusion: { in: ['daily', 'weekly', 'monthly', 'yearly'] }, if: -> { repeat_type.present? }
    validates :interval, presence: true, if: -> { repeat_type.present? }
    validates :interval, inclusion: { in: 1..10 }, if: -> { interval.present? }
    validates :repeat_base, presence: true, if: -> { repeat_type == 'monthly' }
    validates :wdays, presence: true, if: -> { repeat_type == 'weekly' }

    before_save :save_repeat_plan, if: -> { repeat? }
  end

  def repeat?
    repeat_type.present?
  end

  def repeat_type_options
    [:daily, :weekly].map do |name|
      [I18n.t("gws/schedule.options.repeat_type.#{name}"), name.to_s]
    end
  end

  def repeat_base_options
    [:date, :wday].map do |name|
      [I18n.t("gws/schedule.options.repeat_base.#{name}"), name.to_s]
    end
  end

  def interval_options
    1..10
  end

  private

  def repeat_plan_fields
    [:repeat_type, :interval, :repeat_start, :repeat_end, :repeat_base, :wdays]
  end

  def validate_repeat
    self.interval = interval.to_i if interval.present?
    self.repeat_start = Time.zone.parse(repeat_start) rescue nil
    self.repeat_end = Time.zone.parse(repeat_end) rescue nil
    self.wdays = wdays.select(&:present?).map(&:to_i) if wdays.present?
  end

  def save_repeat_plan
    return if cur_site.blank?
    return if message.blank?

    dates = Gws::Schedule::DateEnumerator.new(
      repeat_type: repeat_type, repeat_start: repeat_start, repeat_end: repeat_end,
      interval: interval, wdays: wdays, repeat_base: repeat_base
    )
    dates.each do |date|
      date = date.in_time_zone.change(hour: deliver_date.hour, min: deliver_date.min, sec: 0)
      next if date <= deliver_date

      item = self.class.site(cur_site).where(deliver_date: date).first
      item ||= self.class.new
      item.cur_site = cur_site
      item.cur_user = cur_user
      item.in_ready = in_ready
      item.message = message
      item.deliver_date = date
      item.save
    end
  end
end
