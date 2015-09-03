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
  end
end
