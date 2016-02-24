class Gws::Schedule::Holiday
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name "gws_users", :edit

  field :state, type: String, default: 'public'
  field :name, type: String

  # 期間/検索用
  field :start_at, type: DateTime
  field :end_at, type: DateTime

  # 終日期間/入力用
  field :start_on, type: Date
  field :end_on, type: Date

  permit_params :name, :start_on, :end_on, :start_at, :end_at

  before_validation :set_dates_on
  before_validation :set_datetimes_at

  validates :name, presence: true, length: { maximum: 80 }
  validates :start_at, presence: true
  validates :end_at, presence: true

  validate :validate_datetimes_at

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria = criteria.where :end_at.gte => params[:start] if params[:start].present?
    criteria = criteria.where :start_at.lte => params[:end] if params[:end].present?
    criteria
  }

  def allday?
    true
  end

  def calendar_format
     { className: 'fc-holiday', title: "  #{name}",
       start: start_at, end: (end_at + 1.day).to_date, allDay: true, editable: false }
  end

  private
    def set_dates_on
      self.start_on = Time.zone.today if start_on.blank?
      self.end_on   = start_on if end_on.blank?
      self.end_on   = start_on if start_on > end_on
      self.start_at = Time.zone.local start_on.year, start_on.month, start_on.day, 0, 0, 0
      self.end_at   = Time.zone.local end_on.year, end_on.month, end_on.day, 23, 59, 59
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
