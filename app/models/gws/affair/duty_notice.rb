class Gws::Affair::DutyNotice
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name "gws_affair_duty_hours"

  seqid :id

  field :name, type: String
  field :notice_type, type: String
  field :threshold_hour, type: Integer
  field :body, type: String

  permit_params :name
  permit_params :notice_type
  permit_params :threshold_hour
  permit_params :body

  validates :name, presence: true
  validates :notice_type, presence: true
  validates :threshold_hour, presence: true
  validates :body, presence: true

  def notice_messages(duty_calendar, user, time = Time.zone.now)
    case notice_type
    when "month_time_limit"
      month_time_limit_messages(duty_calendar, user, time)
    when "week_time_limit"
      week_time_limit_messages(duty_calendar, user, time)
    else
      []
    end
  end

  def month_time_limit_messages(duty_calendar, user, time)
    total_working_minute = duty_calendar.total_working_minute_of_month(user, time)

    messages = []
    if total_working_minute >= (threshold_hour * 60)
      messages << "[#{I18n.l(time.to_date, format: :attendance_year_month)}] #{body}"
    end
    messages
  end

  def week_time_limit_messages(duty_calendar, user, time)
    times = []
    beginning_of_week = time.beginning_of_month
    while beginning_of_week.month == time.month
      times << beginning_of_week
      beginning_of_week = beginning_of_week.advance(days: 7)
    end

    messages = []
    times.each do |time|
      total_working_minute = duty_calendar.total_working_minute_of_week(user, time)
      if total_working_minute >= (threshold_hour * 60)
        messages << "[#{I18n.l(time.beginning_of_week.to_date, format: :attendance_month_day)}] #{body}"
      end
    end

    messages
  end

  def notice_type_options
    I18n.t("gws/affair.options.notice_type").map { |k, v| [v, k] }
  end

  def period_type_options
    I18n.t("gws/affair.options.period_type").map { |k, v| [v, k] }
  end

  class << self
    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end
end
