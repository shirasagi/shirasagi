class Gws::Affair::CapitalYear::Importer::Member < Gws::Affair::CapitalYear::Importer::Base
  include ActiveModel::Model

  delegate :last_year, to: :year

  def header_t(key)
    I18n.t("gws/affair.export.leave_setting.#{key}")
  end

  def headers
    h = %w(name staff_address_uid).map { |k| header_t(k) }
    h += last_year_headers if last_year
    h += %w(count).map { |k| header_t(k) }
    h
  end

  def last_year_headers
    %w(count leaved_count effective_count).map do |k|
      I18n.t("gws/affair.export.leave_setting.#{k}") + "（#{last_year.name}）"
    end
  end

  def enum_csv
    yearly_leave_settings = year.yearly_leave_settings.allow(:read, cur_user, site: cur_site)

    if last_year
      last_yearly_leave_settings = last_year.yearly_leave_settings.allow(:read, cur_user, site: cur_site)
    else
      last_yearly_leave_settings = model.none
    end

    Enumerator.new do |y|
      y << encode_sjis(headers.to_csv)
      Gws::User.site(cur_site).active.order_by_title(cur_site).each do |user|
        setting = yearly_leave_settings.in(target_user_id: user.id).first
        last_year_setting = last_yearly_leave_settings.in(target_user_id: user.id).first

        last_year_count = nil
        leaved_count = nil
        effective_count = nil

        if last_year_setting
          last_year_count = last_year_setting.count
          leave_files = last_year_setting.annual_leave_files
          minutes = leave_files.map(&:leave_minutes_in_query).sum
          effective_minutes = (last_year_setting.annual_leave_minutes(cur_site) - minutes)
          effective_minutes = effective_minutes > 0 ? effective_minutes : 0

          leaved_count = Gws::Affair::Utils.leave_minutes_to_day(cur_site, minutes)
          effective_count = Gws::Affair::Utils.leave_minutes_to_day(cur_site, effective_minutes)
        end

        count = nil
        if setting
          count = setting.count
        end

        line = []
        line << user.name
        line << user.staff_address_uid

        if last_year
          line << last_year_count
          line << leaved_count
          line << effective_count
        end

        line << count
        y << encode_sjis(line.to_csv)
      end
    end
  end

  def import
    @imported = 0
    validate_import
    return false unless errors.empty?

    table = CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
    table.each_with_index do |row, i|
      update_row(row, i + 2)
    end
    return errors.empty?
  end

  def update_row(row, index)
    staff_address_uid = row[I18n.t("gws/affair.export.leave_setting.staff_address_uid")].to_s.strip
    count = row[I18n.t("gws/affair.export.leave_setting.count")].to_s.strip

    if staff_address_uid.blank? || count.blank?
      return
    end

    target_user = Gws::User.active.where(staff_address_uid: staff_address_uid).first
    if target_user.nil?
      self.errors.add :base, :not_found_target_user, line_no: index, staff_address_uid: staff_address_uid
      return false
    end

    item = model.where(year_id: year.id, target_user_id: target_user.id).first
    item ||= model.new

    item.site = cur_site
    item.user = cur_user
    item.year = year
    item.target_user = target_user
    item.count = count.to_i

    if item.save
      @imported += 1
    else
      set_errors(item, index)
    end
  end
end
