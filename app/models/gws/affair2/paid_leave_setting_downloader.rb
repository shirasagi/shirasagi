class Gws::Affair2::PaidLeaveSettingDownloader
  extend SS::Translation
  include ActiveModel::Model
  include SS::PermitParams

  attr_accessor :site, :year, :start_date, :close_date

  delegate :t, to: Gws::Affair2::AttendanceSetting

  def initialize(site, year)
    @site = site
    @year = year
    @start_date = Time.zone.local(@year, 1, 1)
    @close_date = start_date.end_of_year
  end

  def template_enum_csv(options = {})
    attendace_settings = Gws::Affair2::AttendanceSetting.site(site).and_between(start_date, close_date)

    paid_leave_settings = {}
    attendace_settings.each do |item|
      paid_leave_settings[item.id] = item.paid_leave_settings.where(year: year).first
    end

    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      drawer.column :id do
        drawer.head { Gws::Affair2::PaidLeaveSetting.t(:id) }
        drawer.body do |item|
          paid_leave_setting = paid_leave_settings[item.id]
          next nil if paid_leave_setting.nil?
          paid_leave_setting.id
        end
      end
      drawer.column :user_id do
        drawer.head { Gws::Affair2::PaidLeaveSetting.t(:user_id) }
        drawer.body { |item| item.user.try(:name) }
      end
      drawer.column :attendance_setting do
        drawer.head { Gws::Affair2::PaidLeaveSetting.t(:attendance_setting_id) }
        drawer.body { |item| "#{item.id},#{item.name}" }
      end
      drawer.column :year do
        drawer.head { Gws::Affair2::PaidLeaveSetting.t(:year) }
        drawer.body { year }
      end
      drawer.column :carryover_minutes do
        drawer.head { Gws::Affair2::PaidLeaveSetting.t(:carryover_minutes) }
        drawer.body do |item|
          paid_leave_setting = paid_leave_settings[item.id]
          next nil if paid_leave_setting.nil?
          paid_leave_setting.carryover_minutes
        end
      end
      drawer.column :additional_minutes do
        drawer.head { Gws::Affair2::PaidLeaveSetting.t(:additional_minutes) }
        drawer.body do |item|
          paid_leave_setting = paid_leave_settings[item.id]
          next nil if paid_leave_setting.nil?
          paid_leave_setting.additional_minutes
        end
      end
    end
    drawer.enum(attendace_settings, options)
  end

  def remind_enum_csv(options = {})
    items = Gws::Affair2::PaidLeaveSetting.site(site).where(year: year)

    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      drawer.column :id
      drawer.column :user_id do
        drawer.head { Gws::Affair2::PaidLeaveSetting.t(:user_id) }
        drawer.body { |item| item.user.try(:name) }
      end
      drawer.column :attendance_setting do
        drawer.head { Gws::Affair2::PaidLeaveSetting.t(:attendance_setting_id) }
        drawer.body { |item| "#{item.id},#{item.name}" }
      end
      drawer.column :year
      drawer.column :carryover_minutes
      drawer.column :additional_minutes
      drawer.column :effective_minutes
      drawer.column :used_minutes
      drawer.column :remind_minutes
    end
    drawer.enum(items, options )
  end
end
