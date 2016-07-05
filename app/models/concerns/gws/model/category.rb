module Gws::Model::Category
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Gws::Schedule::Colorize
  include SS::Fields::DependantNaming

  included do
    store_in collection: "gws_categories"

    seqid :id
    field :model, type: String
    field :state, type: String, default: "public"
    field :name, type: String
    field :color, type: String, default: -> { default_color }
    field :order, type: Integer

    permit_params :state, :name, :color, :order

    validates :model, presence: true
    validates :state, presence: true
    validates :name, presence: true, length: { maximum: 80 }
    validates :color, presence: true, if: ->{ color_required? }
    validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }

    scope :search, ->(params) do
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria
    end
  end

  module ClassMethods
    def tree_sort(options = {})
      SS::TreeList.build self, options
    end
  end

  def trailing_name
    @trailing_name ||= name.split("/")[depth..-1].join("/")
  end

  def depth
    @depth ||= begin
      count = 0
      full_name = ""
      name.split("/").map do |part|
        full_name << "/" if full_name.present?
        full_name << part

        break if name == full_name

        found = self.class.where(name: full_name).first
        break if found.blank?

        count += 1
      end
      count
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
