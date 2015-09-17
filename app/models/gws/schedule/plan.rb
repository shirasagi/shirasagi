class Gws::Schedule::Plan
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Schedule::Repeat
  include Gws::Addon::Schedule::Member
  include Gws::Addon::Schedule::Facility
  include Gws::Addon::GroupPermission

  attr_accessor :api

  field :name, type: String
  field :text, type: String
  field :start_at, type: DateTime
  field :end_at, type: DateTime
  field :allday, type: String

  belongs_to :category, class_name: 'Gws::Schedule::Category'

  permit_params :api, :name, :text, :start_at, :end_at, :allday, :category_id

  before_validation :validate_datetimes_on_drop, if: -> { api == 'drop' }
  before_validation :validate_datetimes, if: -> { start_at.present? && repeat_type.blank? }

  validates :name, presence: true
  validates :start_at, presence: true, if: -> { repeat_type.blank? }
  #validates :end_at, presence: true, if: -> { repeat_type.blank? }
  validates :allday, inclusion: { in: [nil, "", "allday"] }

  validate do
    errors.add :end_at, :greater_than, count: t(:start_at) if end_at.present? && end_at <= start_at
  end

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
      [
        [I18n.t("gws/schedule.options.allday.allday"), "allday"]
      ]
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
      if start_at.to_date == end_at.to_date
        data.merge! className: 'fc-event-one'
      else
        data.merge! className: 'fc-event-days'
      end
      if repeat_plan_id
        data[:title] = " " + data[:title]
        data[:className] += " fc-event-repeat"
      end
      data
    end

  private
    def validate_datetimes_on_drop
      return if end_at.present?
      time = [end_at_was.hour, end_at_was.min]
      self.end_at = Time.local start_at.year, start_at.month, start_at.day, time[0], time[1], 0
    end

    def validate_datetimes
      if allday?
        self.start_at = start_at.to_date
        self.end_at = start_at if end_at.blank?
        self.end_at = (end_at + 1).to_date if end_at.strftime('%H%M%S') =~ /[^0]/
        self.end_at = (end_at + 1).to_date if start_at.to_date == end_at.to_date
      else
        self.end_at = start_at if end_at.blank?
        self.end_at = end_at + 1.minutes if start_at == end_at
      end
    end
end
