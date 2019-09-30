class Gws::Affair::Enumerator::Rkk::RegularUsers < Gws::Affair::Enumerator::Base
  def initialize(prefs, users, params)
    @prefs = prefs
    @users = users
    @params = params

    super() do |y|
      y << bom + encode(headers.to_csv)

      @prefs.each do |user_id, values|
        values.each do |user_staff_address_uid, values|
          values.each do |project_code, values|
            enum_record(y, user_id, user_staff_address_uid, project_code, values)
          end
        end
      end
    end
  end

  def headers
    I18n.t("gws/rkk.export.overtime").to_a
  end

  private

  def enum_record(yielder, user_id, user_staff_address_uid, project_code, values)
    user = Gws::User.find(user_id) rescue nil

    under_duty_day    = values.dig("under_threshold", "duty_day_time_minute").to_i
    under_duty_night  = values.dig("under_threshold", "duty_night_time_minute").to_i
    under_leave_day   = values.dig("under_threshold", "leave_day_time_minute").to_i
    under_leave_night = values.dig("under_threshold", "leave_night_time_minute").to_i
    under_week_out    = values.dig("under_threshold", "week_out_compensatory_minute").to_i

    over_duty_day    = values.dig("over_threshold", "duty_day_time_minute").to_i
    over_duty_night  = values.dig("over_threshold", "duty_night_time_minute").to_i
    over_leave_day   = values.dig("over_threshold", "leave_day_time_minute").to_i
    over_leave_night = values.dig("over_threshold", "leave_night_time_minute").to_i
    over_week_out    = values.dig("over_threshold", "week_out_compensatory_minute").to_i

    duty_day_in_work = values.dig("under_threshold", "duty_day_in_work_time_minute").to_i

    # under_duty_day    1.25
    # under_duty_night  1.5
    # under_leave_day   1.35
    # under_leave_night 1.6
    # under_week_out    0.25
    #
    # over_duty_day     1.5
    # over_duty_night   1.75
    # over_leave_day    1.5
    # over_leave_night  1.75
    # over_week_out     0.5
    #
    # duty_day_in_work  1.0

    line = []
    line << "20"
    line << "200"
    1.times { line << "" }
    line << user.try(:organization_uid)
    line << user_staff_address_uid
    line << user.try(:name)
    line << user.try(:kana)
    10.times { line << "" }
    line << project_code
    1.times { line << "" }
    line << format_minute(under_duty_day)
    line << format_minute(under_duty_night + over_duty_day + over_leave_day)
    line << format_minute(under_leave_day)
    line << format_minute(under_leave_night)
    line << format_minute(under_week_out)
    line << format_minute(over_duty_night + over_leave_night)
    line << format_minute(over_week_out)
    line << format_minute(duty_day_in_work)
    16.times { line << "" }

    yielder << encode(line.to_csv)
  end

  def format_minute(minute)
    hours = minute / 60
    minutes = minute % 60

    hours += 1 if minutes >= 30
    hours
  end
end
