module Gws::Schedule::Planable
  extend ActiveSupport::Concern
  extend SS::Translation

  attr_accessor :api, :api_start, :api_end

  included do
    # 状態
    field :state, type: String, default: 'public'

    # 名称
    field :name, type: String

    # 終日期間/入力用
    field :start_on, type: Date
    field :end_on, type: Date

    # 期間/検索用
    field :start_at, type: DateTime
    field :end_at, type: DateTime

    # 終日
    field :allday, type: String

    permit_params :api, :api_start, :api_end, :category_id
    permit_params :state, :name, :start_on, :end_on, :start_at, :end_at, :allday

    before_validation :set_from_drop_time_api, if: -> { api == 'drop' && api_start.index('T') }
    before_validation :set_from_drop_date_api, if: -> { api == 'drop' && !api_start.index('T') }
    before_validation :set_from_resize_time_api, if: -> { api == 'resize' && api_start.index('T') }
    before_validation :set_from_resize_date_api, if: -> { api == 'resize' && !api_start.index('T') }
    before_validation :set_dates_on
    before_validation :set_datetimes_at

    validates :name, presence: true, length: { maximum: 80 }
    validates :start_at, presence: true
    validates :end_at, presence: true
    validates :allday, inclusion: { in: [nil, "", "allday"] }

    validate :validate_datetimes_at

    default_scope ->{
      order_by start_at: 1
    }
    scope :and_public, ->{
      where state: 'public'
    }
    scope :between_dates, ->(target_start, target_end) {
      where :end_at.gte => target_start, :start_at.lte => target_end
    }
    scope :search, ->(params) {
      criteria = where({})
      return criteria if params.blank?

      if params[:start].present? && params[:end].present?
        criteria = criteria.between_dates params[:start], params[:end]
      end

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria
    }
  end

  def allday_options
    [[I18n.t("gws/schedule.options.allday.allday"), "allday"]]
  end

  def allday?
    allday == "allday"
  end

  def reminder_user_ids
    member_ids
  end

  private
    # API / Mode: month, week, day
    # - 時間予定(複数日)を別の日に移動
    # - 終日予定を時間予定に変更
    def set_from_drop_time_api
      self.start_at = api_start

      date = api_end.present? ? Time.zone.parse(api_end) : Time.zone.parse(api_start)
      time = allday? ? [start_at.hour, start_at.min] : [date.hour, date.min]
      self.end_at = Time.zone.local date.year, date.month, date.day, time[0], time[1]
      self.allday = nil
    end

    # API / Mode: month, week
    # - 終日予定を別の日に移動
    def set_from_drop_date_api
      self.start_on = api_start
      self.end_on   = api_end.present? ? (Date.parse(api_end) - 1.day) : api_start
      self.allday   = 'allday'
    end

    # API / Mode: day
    # - 時間予定の時間を変更
    def set_from_resize_time_api
      self.start_at = api_start
      self.end_at   = api_end
    end

    # API / Mode: month, week
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
