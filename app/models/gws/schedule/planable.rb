module Gws::Schedule::Planable
  extend ActiveSupport::Concern

  included do
    attr_accessor :api

    field :name, type: String
    field :text, type: String
    field :start_at, type: DateTime
    field :end_at, type: DateTime
    field :allday, type: String

    belongs_to :category, class_name: 'Gws::Schedule::Category'
    embeds_ids :members, class_name: "Gws::User"
    embeds_ids :facilities, class_name: "Gws::Facility"

    permit_params :api, :name, :text, :start_at, :end_at, :allday, :category_id
    permit_params member_ids: [], facility_ids: []

    validates :name, presence: true
    validates :start_at, presence: true
    validates :end_at, presence: true
    validates :allday, inclusion: { in: [nil, "", "allday"] }
    validates :member_ids, presence: true

    before_validation do
      if allday?
        self.start_at = start_at.to_date
        self.end_at = start_at if end_at.blank?
        self.end_at = (end_at + 1).to_date if self.end_at.strftime('%H%M%S') =~ /[^0]/
        self.end_at = (end_at + 1).to_date if self.start_at.to_date == self.end_at.to_date
      elsif end_at.blank?
        if api == 'drop'
          self.end_at = DateTime.zone.new(
            start_at.year, start_at.month, start_at.day,
            end_at_was.hour, end_at_was.min, end_at_was.sec
          )
        else
          self.end_at = start_at + 1.minutes if start_at
        end
      end
    end

    validate do
      errors.add :end_at, :greater_than, count: t(:start_at) if end_at.present? && end_at <= start_at
    end

    scope :member, ->(user) { where member_ids: user.id }
    scope :facility, ->(item) { where facility_ids: item.id }

    scope :search, ->(params) {
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria = criteria.where :start_at.gte => params[:start] if params[:start].present?
      criteria = criteria.where :end_at.lte => params[:end] if params[:end].present?
      criteria
    }
  end

  public
    def allday_options
      [
        [I18n.t("gws_schedule.options.allday.allday"), "allday"]
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
        data[:className] += " fc-event-repeat"
      end
      data
    end
end
