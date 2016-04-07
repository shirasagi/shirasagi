module Gws::Model::Category
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Gws::Content::Targetable
  include Gws::Schedule::Colorize

  included do
    store_in collection: "gws_categories"

    seqid :id
    field :model, type: String
    field :state, type: String, default: "public"
    field :name, type: String
    field :color, type: String, default: "#4488bb"

    permit_params :state, :name, :color

    validates :model, presence: true
    validates :state, presence: true
    validates :name, presence: true, length: { maximum: 40 }
    validates :color, presence: true

    scope :search, ->(params) do
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria
    end
  end
end
