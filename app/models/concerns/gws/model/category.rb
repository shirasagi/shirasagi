module Gws::Model::Category
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Gws::Content::Targetable
  include Gws::Schedule::Colorize
  include SS::Fields::DependantNaming

  included do
    store_in collection: "gws_categories"

    seqid :id
    field :model, type: String
    field :state, type: String, default: "public"
    field :name, type: String
    field :color, type: String, default: -> { default_color }

    permit_params :state, :name, :color

    validates :model, presence: true
    validates :state, presence: true
    validates :name, presence: true, length: { maximum: 80 }
    validates :color, presence: true, if: ->{ color_required? }

    scope :search, ->(params) do
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria
    end
  end

  private
    def color_required?
      true
    end

    def default_color
      "#4488bb"
    end

    def dependant_scope
      self.class.site(@cur_site || site)
    end
end
