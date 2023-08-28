module Gws::Addon::Affair::AnnualLeaveSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :count, type: Integer, default: 20
    permit_params :count
  end

  def annual_leave_minutes(site)
    # 1日の有給に付与される有効時間は7.75時間とする
    # - 8:30 〜 17:00（休憩 12:15 〜 13:00）
    site.upper_day_leave_minute * count
  end

  def annual_leave_files(opts = {})
    opts[:types] = %w(annual_leave)
    leave_files(opts)
  end

  module ClassMethods
    def effective_annual_leave_minutes(site, user, date)
      setting = self.and_date(site, user, date).first
      return 0 if setting.nil?

      leave_files = setting.annual_leave_files
      leave_dates = leave_files.map { |item| item.leave_dates }.flatten
      minutes = leave_dates.map(&:minute).sum

      count = (setting.annual_leave_minutes(site) - minutes)
      count > 0 ? count : 0
    end

    def obtainable_annual_leave?(site, user, date, leave_file)
      setting = self.and_date(site, user, date).first
      return false if setting.nil?

      leave_files = setting.annual_leave_files
      leave_files = leave_files.reject { |file| file.id == leave_file.id } if leave_file
      leave_dates = leave_files.map { |item| item.leave_dates }.flatten
      minutes = leave_dates.map(&:minute).sum

      count = (setting.annual_leave_minutes(site) - minutes)
      count -= leave_file.in_leave_dates.map(&:minute).sum
      count >= 0
    end
  end
end
