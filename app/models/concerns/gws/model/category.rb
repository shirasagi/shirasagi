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
    validates :color, "ss/color" => true
    validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }
  end

  module ClassMethods
    def tree_sort(options = {})
      SS::TreeList.build self, options
    end

    def search(params)
      return all if params.blank?
      all.search_name(params).search_keyword(params)
    end

    def search_name(params)
      return all if params.blank? || params[:name].blank?
      all.where(name: params[:name])
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?

      all.keyword_in params[:keyword], :name, :color
    end
  end

  def trailing_name
    @trailing_name ||= name.to_s.split("/")[depth..-1].join("/")
  end

  def depth
    @depth ||= begin
      count = 0
      full_name = ""
      name.to_s.split("/").map do |part|
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

  def parent_category
    return nil if depth.blank? || depth <= 0 || name.blank?

    parent_name = ::File.dirname(name)
    return nil if parent_name.blank? || parent_name == "."

    criteria = self.class.all
    criteria = criteria.site(@cur_site || site)
    criteria = criteria.where(name: parent_name)
    criteria.first
  end

  # rubocop:disable Style::RedundantAssignment
  def descendants_category
    return self.class.none if name.blank?

    criteria = self.class.all
    criteria = criteria.site(@cur_site || site)
    criteria = criteria.where(name: /^#{::Regexp.escape(name)}\//)
    criteria
  end
  # rubocop:enable Style::RedundantAssignment

  private

  def color_required?
    true
  end

  def default_color
    "#4488bb"
  end

  def dependant_scope
    s = @cur_site || site
    s ? self.class.site(s) : self.class.none
  end
end
