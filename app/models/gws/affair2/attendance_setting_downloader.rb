class Gws::Affair2::AttendanceSettingDownloader
  extend SS::Translation
  include ActiveModel::Model
  include SS::PermitParams

  attr_accessor :site

  delegate :t, to: Gws::Affair2::AttendanceSetting

  def initialize(site)
    @site = site
  end

  def all_enum_csv(options = {})
    items = Gws::Affair2::AttendanceSetting.site(site)

    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      drawer.column :id
      drawer.column :user_id do
        drawer.head { self.t(:user_id) }
        drawer.body do |item|
          item.user ? "#{item.user.id},#{item.user.name}" : nil
        end
      end
      drawer.column :organization_uid
      drawer.column :start_date do
        drawer.head { self.t(:start_date) }
        drawer.body { |item| item.start_date.try(:to_date) }
      end
      drawer.column :close_date do
        drawer.head { self.t(:close_date) }
        drawer.body { |item| item.close_date.try(:to_date) }
      end
      drawer.column :duty_setting do
        drawer.head { self.t(:duty_setting_id) }
        drawer.body { |item| item.duty_setting.try(:name) }
      end
      drawer.column :leave_setting do
        drawer.head { self.t(:leave_setting_id) }
        drawer.body { |item| item.leave_setting.try(:name) }
      end
    end
    drawer.enum(items, options)
  end

  def no_setting_enum_csv(options = {})
    user_ids = Gws::Affair2::AttendanceSetting.site(site).pluck(:user_id)
    users = Gws::User.site(site).active.nin(id: user_ids).order_by_title(site)

    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      drawer.column :id do
        drawer.head { self.t(:id) }
        drawer.body { nil }
      end
      drawer.column :user_id do
        drawer.head { self.t(:user_id) }
        drawer.body { |user| "#{user.id},#{user.name}" }
      end
      drawer.column :organization_uid
      drawer.column :start_date do
        drawer.head { self.t(:start_date) }
        drawer.body { nil }
      end
      drawer.column :close_date do
        drawer.head { self.t(:close_date) }
        drawer.body { nil }
      end
      drawer.column :duty_setting do
        drawer.head { self.t(:duty_setting_id) }
        drawer.body { nil }
      end
      drawer.column :leave_setting do
        drawer.head { self.t(:leave_setting_id) }
        drawer.body { nil }
      end
    end
    drawer.enum(users, options)
  end
end
