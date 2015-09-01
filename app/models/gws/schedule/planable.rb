module Gws::Schedule::Planable
  extend ActiveSupport::Concern

  included do
    field :name, type: String
    field :text, type: String
    field :start_at, type: DateTime
    field :end_at, type: DateTime
    field :allday, type: String

    belongs_to :category, class_name: 'Gws::Schedule::Category'

    permit_params :name, :text, :start_at, :end_at, :allday, :category_id

    #validates :text, presence: true
    validates :start_at, presence: true
    #validates :end_at, presence: true
    validates :allday, inclusion: { in: [nil, "", "allday"] }

    validate do
      errors.add :end_at, :greater_than, count: t(:start_at) if end_at.present? && end_at < start_at
    end
  end
end
