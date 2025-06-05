class Gws::Affair2::AttendanceSettingImporter
  extend SS::Translation
  include ActiveModel::Model
  include SS::PermitParams

  attr_accessor :cur_site, :in_file

  permit_params :in_file

  validates :cur_site, presence: true
  validates :in_file, presence: true
  validate :validate_in_file, if: ->{ in_file }

  def model
    Gws::Affair2::AttendanceSetting
  end

  def site
    cur_site
  end

  def validate_in_file
    if !SS::Csv.valid_csv?(in_file, headers: true, required_headers: required_headers)
      self.errors.add :base, :invalid_csv
    end
  end

  def required_headers
    [
      :id,
      :user_id,
      :organization_uid,
      :start_date,
      :close_date,
      :duty_setting_id,
      :leave_setting_id
    ].map { |k| model.t(k) }
  end

  def import
    return false if invalid?

    SS::Csv.foreach_row(in_file, headers: true) do |row, idx|
      @idx = idx

      item = find_or_initialize_attendance(row)
      next unless item

      user = find_user(row)
      next unless user

      item.cur_site = site
      item.cur_user = user
      item.organization_uid = row[model.t(:organization_uid)].to_s.strip
      item.duty_setting = find_duty_setting(row)
      item.leave_setting = find_leave_setting(row)

      # start, close
      start_date = row[model.t(:start_date)].to_s.strip
      close_date = row[model.t(:close_date)].to_s.strip

      begin
        start_date = start_date.present? ? Date.parse(start_date) : nil
        close_date = close_date.present? ? Date.parse(close_date) : nil
      rescue => e
        self.errors.add :base, "#{@idx + 1}行目: 開始、終了の日付が不正です。"
        next
      end

      item.start_date = nil
      item.close_date = nil
      if start_date
        item.in_start_year = start_date.year
        item.in_start_month = start_date.month
      end
      if close_date
        item.in_close_year = close_date.year
        item.in_close_month = close_date.month
      end

      if !item.save
        SS::Model.copy_errors(item, self, prefix: "#{@idx + 1}行目: ")
      end
    end

    errors.blank?
  end

  def find_or_initialize_attendance(row)
    id = row[model.t(:id)].to_s.strip
    return model.new if id.blank?

    item = model.site(site).find(id) rescue nil
    return item if item

    self.errors.add :base, "#{@idx + 1}行目: 出退勤設定が見つかりません。(#{id})"
    return false
  end

  def find_user(row)
    user_value = row[model.t(:user_id)].to_s.strip
    user_id = user_value.split(/,/)[0].to_i
    user = Gws::User.site(site).find(user_id) rescue nil
    return user if user

    self.errors.add :base, "#{@idx + 1}行目: ユーザーが見つかりません。(#{user_value})"
    return false
  end

  def find_duty_setting(row)
    name = row[model.t(:duty_setting_id)].to_s.strip
    Gws::Affair2::DutySetting.site(site).where(name: name).first
  end

  def find_leave_setting(row)
    name = row[model.t(:leave_setting_id)].to_s.strip
    Gws::Affair2::LeaveSetting.site(site).where(name: name).first
  end
end
