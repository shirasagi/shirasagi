class Gws::Schedule::Plan
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Schedule::Repeat
  include Gws::Addon::Schedule::Member
  include Gws::Addon::Schedule::Facility
  include Gws::Addon::GroupPermission

  attr_accessor :api, :api_start, :api_end

  field :name, type: String
  field :text, type: String

  # 期間/検索用
  field :start_at, type: DateTime
  field :end_at, type: DateTime

  # 終日期間/入力用
  field :start_on, type: Date
  field :end_on, type: Date

  # 終日
  field :allday, type: String

  belongs_to :category, class_name: 'Gws::Schedule::Category'

  permit_params :api, :api_start, :api_end
  permit_params :name, :text, :start_on, :end_on, :start_at, :end_at, :allday, :category_id

  before_validation :set_from_drop_api, if: -> { api == 'drop' }
  before_validation :set_from_resize_api, if: -> { api == 'resize' }
  before_validation :set_dates_on
  before_validation :set_datetimes_at

  validates :name, presence: true, length: { maximum: 80 }
  validates :start_at, presence: true, if: -> { repeat? }
  validates :end_at, presence: true, if: -> { repeat? }
  validates :allday, inclusion: { in: [nil, "", "allday"] }

  validate :validate_datetimes_at

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria = criteria.where :start_at.gte => params[:start] if params[:start].present?
    criteria = criteria.where :end_at.lte => params[:end] if params[:end].present?
    criteria
  }

  public
    def allday_options
      [[I18n.t("gws/schedule.options.allday.allday"), "allday"]]
    end

    def allday?
      allday == "allday"
    end

    def category_options
      cond = {
        site_id: @cur_site ? @cur_site.id: site_id,
        user_id: @cur_user ? @cur_user.id : user_id
      }
      Gws::Schedule::Category.where(cond).map { |c| [c.name, c.id] }
    end

    # event options
    # http://fullcalendar.io/docs/event_data/Event_Object/
    def calendar_format
      data = { id: id, title: ERB::Util.h(name), start: start_at, end: end_at, allDay: allday? }

      if allday? || start_at.to_date != end_at.to_date
        data.merge! className: 'fc-event-days'
      else
        data.merge! className: 'fc-event-one'
      end

      if allday?
        data.merge! start: start_at.to_date
        data.merge! end: (end_at + 1.days).to_date
        data[:className] += " fc-event-allday"
      end

      if repeat_plan_id
        data[:title]      = " #{data[:title]}"
        data[:className] += " fc-event-repeat"
      end
      data
    end

  private
    # @example
    #   [allday] api=drop, api_start=2015-09-30, api_end=2015-10-02
    #   [a day]  api=drop, api_start=2015-09-30T17:55:22, api_end=
    def set_from_drop_api
      if allday?
        self.start_on = api_start
        self.end_on   = Date.parse(api_end) - 1.days
      else
        date = api_end.present? ? Date.parse(api_end) : Date.parse(api_start)
        time = [end_at.hour, end_at.min]
        self.start_at = api_start
        self.end_at   = Time.zone.local date.year, date.month, date.day, time[0], time[1]
      end
    end

    # @example
    #   [allday] api=resize, api_start=2015-09-29, api_end=2015-10-02
    #   [a day]  none
    def set_from_resize_api
      self.start_on = api_start
      self.end_on   = Date.parse(api_end) - 1.days
    end

    def set_dates_on
      if allday?
        self.start_on = Time.zone.today if start_on.blank?
        self.end_on   = start_on if end_on.blank?
        self.end_on   = start_on if start_on > end_on
        self.start_at = Time.zone.local start_on.year, start_on.month, start_on.day, 0, 0, 0
        self.end_at   = Time.zone.local end_on.year, end_on.month, end_on.day, 23, 59, 59
      else
        self.start_on = nil
        self.end_on   = nil
      end
    end

    def set_datetimes_at
      self.start_at = Time.zone.now.strftime('%Y/%m/%d %H:00') if start_at.blank?
      self.end_at   = start_at if end_at.blank?
      self.end_at   = start_at if start_at > end_at
    end

    def validate_datetimes_at
      errors.add :end_at, :greater_than, count: t(:start_at) if start_at > end_at
    end
end
