class Gws::Affair::HolidayCalendar
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name "gws_affair_duty_settings", :edit

  field :name, type: String
  has_many :holidays, class_name: 'Gws::Schedule::Holiday', dependent: :destroy, inverse_of: :holiday_calendar

  permit_params :name

  validates :name, presence: true

  %w(sunday monday tuesday wednesday thursday friday saturday national_holiday).each do |wday|
    field "#{wday}_type", type: String
    permit_params "#{wday}_type".to_sym
    validates "#{wday}_type", presence: true, inclusion: { in: %w(workday holiday), allow_blank: true }
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

  def wday_type_options
    %w(workday holiday).map do |v|
      [ I18n.t("gws/affair.options.wday_type.#{v}"), v ]
    end
  end

  %w(sunday monday tuesday wednesday thursday friday saturday national_holiday).each do |wday|
    alias_method "#{wday}_type_options", :wday_type_options
  end

  # 休み
  def leave_day?(date)
    weekly_leave_day?(date) || holiday?(date)
  end

  # 週休日
  def weekly_leave_day?(date)
    date = date.localtime if date.respond_to?(:localtime)
    wday = %w(sunday monday tuesday wednesday thursday friday saturday)[date.wday]
    send("#{wday}_type") == "holiday"
  end

  # 祝日
  def holiday?(date)
    date = date.localtime if date.respond_to?(:localtime)
    return true if HolidayJapan.check(date.to_date)

    Gws::Schedule::Holiday.site(@cur_site || site).
      and_public.
      search(start: date, end: date).present?

    # 日毎の休日設定は利用停止
    #Gws::Schedule::Holiday.site(@cur_site || site).
    #  and_public.
    #  and_holiday_calendar(self).
    #  search(start: date, end: date).present?
  end
end
