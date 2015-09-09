module Gws::Schedule::Planable
  extend ActiveSupport::Concern

  included do
    field :name, type: String
    field :text, type: String
    field :start_at, type: DateTime
    field :end_at, type: DateTime
    field :allday, type: String

    belongs_to :category, class_name: 'Gws::Schedule::Category'
    embeds_ids :members, class_name: "Gws::User"
    embeds_ids :facilities, class_name: "Gws::Facility"

    permit_params :name, :text, :start_at, :end_at, :allday, :category_id
    permit_params member_ids: [], facility_ids: []

    #validates :text, presence: true
    validates :start_at, presence: true
    #validates :end_at, presence: true
    validates :allday, inclusion: { in: [nil, "", "allday"] }
    validates :member_ids, presence: true

    validate do
      errors.add :end_at, :greater_than, count: t(:start_at) if end_at.present? && end_at < start_at
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
end
