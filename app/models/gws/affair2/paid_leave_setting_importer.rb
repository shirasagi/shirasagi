class Gws::Affair2::PaidLeaveSettingImporter
  extend SS::Translation
  include ActiveModel::Model
  include SS::PermitParams

  attr_accessor :cur_site, :in_file

  permit_params :in_file

  validates :cur_site, presence: true
  validates :in_file, presence: true
  validate :validate_in_file, if: ->{ in_file }

  def model
    Gws::Affair2::PaidLeaveSetting
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
      :year,
      :attendance_setting_id,
      :carryover_minutes,
      :additional_minutes
    ].map { |k| model.t(k) }
  end

  def import
    return false if invalid?

    SS::Csv.foreach_row(in_file, headers: true) do |row, idx|
      id = row[model.t(:id)].to_s.strip
      if id.present?
        item = model.site(site).find(id) rescue nil
        if item.nil?
          self.errors.add :base, "#{idx + 1}行目: 年次有給設定が見つかりません。(#{id})"
          next
        end
      else
        item = model.new
      end

      attendance_value = row[model.t(:attendance_setting_id)].to_s.strip
      attendance_setting_id = attendance_value.split(/,/)[0].to_i
      attendance_setting = Gws::Affair2::AttendanceSetting.site(site).find(attendance_setting_id) rescue nil
      if attendance_setting.nil?
        self.errors.add :base, "#{idx + 1}行目: 出勤簿設定が見つかりません。(#{attendance_value})"
        next
      end

      year = row[model.t(:year)].presence
      year = year.to_i if year

      carryover_minutes = row[model.t(:carryover_minutes)].presence
      carryover_minutes = carryover_minutes.to_i if carryover_minutes

      additional_minutes = row[model.t(:additional_minutes)].presence
      additional_minutes = additional_minutes.to_i if additional_minutes

      item.cur_site = site
      item.attendance_setting = attendance_setting
      item.year = year
      item.carryover_minutes = carryover_minutes
      item.additional_minutes = additional_minutes

      if !item.save
        SS::Model.copy_errors(item, self, prefix: "#{idx + 1}行目: ")
      end
    end

    errors.blank?
  end
end
