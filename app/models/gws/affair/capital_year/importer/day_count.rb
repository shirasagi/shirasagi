class Gws::Affair::CapitalYear::Importer::DayCount < Gws::Affair::CapitalYear::Importer::Base
  include ActiveModel::Model

  def header_t(key)
    I18n.t("gws/affair.export.leave_setting.#{key}")
  end

  def headers
    %w(name staff_address_uid count leaved_count effective_count).map { |k| header_t(k) }
  end

  def enum_csv
    yearly_leave_settings = year.yearly_leave_settings.allow(:read, cur_user, site: cur_site)

    Enumerator.new do |y|
      y << encode_sjis(headers.to_csv)
      Gws::User.site(cur_site).active.order_by_title(cur_site).each do |user|
        setting = yearly_leave_settings.in(target_user_id: user.id).first

        count = nil
        leaved_count = nil
        effective_count = nil

        if setting
          count = setting.count
          leave_files = setting.annual_leave_files
          minutes = leave_files.map(&:leave_minutes_in_query).sum
          effective_minutes = (setting.annual_leave_minutes - minutes)
          effective_minutes = effective_minutes > 0 ? effective_minutes : 0

          leaved_count = Gws::Affair::Utils.leave_minutes_to_day(minutes)
          effective_count = Gws::Affair::Utils.leave_minutes_to_day(effective_minutes)
        end

        line = []
        line << user.name
        line << user.staff_address_uid
        line << count
        line << leaved_count
        line << effective_count
        y << encode_sjis(line.to_csv)
      end
    end
  end
end
