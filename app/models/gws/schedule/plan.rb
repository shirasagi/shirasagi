class Gws::Schedule::Plan
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Schedule::Repeat
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Schedule::Member
  include Gws::Addon::Schedule::Facility
  include Gws::Addon::GroupPermission

  attr_accessor :api, :api_start, :api_end

  field :state, type: String, default: 'public'
  field :name, type: String

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
  permit_params :name, :start_on, :end_on, :start_at, :end_at, :allday, :category_id

  before_validation :set_from_drop_time_api, if: -> { api == 'drop' && api_start.index('T') }
  before_validation :set_from_drop_date_api, if: -> { api == 'drop' && !api_start.index('T') }
  before_validation :set_from_resize_time_api, if: -> { api == 'resize' && api_start.index('T') }
  before_validation :set_from_resize_date_api, if: -> { api == 'resize' && !api_start.index('T') }
  before_validation :set_dates_on
  before_validation :set_datetimes_at

  validates :name, presence: true, length: { maximum: 80 }
  validates :start_at, presence: true, if: -> { !repeat? }
  validates :end_at, presence: true, if: -> { !repeat? }
  validates :allday, inclusion: { in: [nil, "", "allday"] }

  validate :validate_datetimes_at

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria = criteria.where :end_at.gte => params[:start] if params[:start].present?
    criteria = criteria.where :start_at.lte => params[:end] if params[:end].present?
    criteria
  }

  def allday_options
    [[I18n.t("gws/schedule.options.allday.allday"), "allday"]]
  end

  def allday?
    allday == "allday"
  end

  def category_options
    cond = { site_id: @cur_site ? @cur_site.id: site_id }
    Gws::Schedule::Category.where(cond).order(name: 1).map { |c| [c.name, c.id] }
  end

  # event options
  # http://fullcalendar.io/docs/event_data/Event_Object/
  def calendar_format
    data = { id: id, title: ERB::Util.h(name), start: start_at, end: end_at, allDay: allday? }

    if allday? || start_at.to_date != end_at.to_date
      data[:className] = 'fc-event-days'
      data[:backgroundColor] = category.color if category
      data[:textColor] = category.text_color if category
    else
      data[:className] = 'fc-event-one'
      data[:textColor] = category.color if category
    end

    if allday?
      data[:start] = start_at.to_date
      data[:end] = (end_at + 1.day).to_date
      data[:className] += " fc-event-allday"
    end

    if repeat_plan_id
      data[:title]      = " #{data[:title]}"
      data[:className] += " fc-event-repeat"
    end
    data
  end

  private
    # Mode: month, week, day
    # - 時間予定(複数日)を別の日に移動
    # - 終日予定を時間予定に変更
    def set_from_drop_time_api
      self.start_at = api_start

      date = api_end.present? ? Date.parse(api_end) : Date.parse(api_start)
      time = allday? ? [start_at.hour, start_at.min] : [end_at.hour, end_at.min]
      self.end_at = Time.zone.local date.year, date.month, date.day, time[0], time[1]
      self.allday = nil
    end

    # Mode: month, week
    # - 終日予定を別の日に移動
    def set_from_drop_date_api
      self.start_on = api_start
      self.end_on   = api_end.present? ? (Date.parse(api_end) - 1.day) : api_start
      self.allday   = 'allday'
    end

    # Mode: day
    # - 時間予定の時間を変更
    def set_from_resize_time_api
      self.start_at = api_start
      self.end_at   = api_end
    end

    # Mode: month, week
    # - 時間予定の終了日を変更
    # - 終日予定の終了日を変更
    def set_from_resize_date_api
      self.start_on = api_start
      self.end_on   = Date.parse(api_end) - 1.day
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
