class Gws::Schedule::FacilitiesController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  before_action :set_category, only: :index

  private
    def category_criteria
      Gws::Facility::Category.site(@cur_site).readable(@cur_user, @cur_site)
    end

    def set_category
      @categories = category_criteria.tree_sort

      category_id = params.dig(:s, :category)
      if category_id.present?
        @category = category_criteria.find(category_id) rescue nil
      end

      @category ||= begin
        c = @categories.find { |c| c.id.present? }
        c = category_criteria.find(c.id) rescue nil
        c
      end
    end

    def category_ids
      return if @category.blank?
      ids = category_criteria.where(name: /^#{Regexp.escape(@category.name)}\//).pluck(:id)
      ids << @category.id
    end

  public
    def index
      Rails.logger.debug("#index: category_ids=#{category_ids}")
      @items = Gws::Facility::Item.site(@cur_site).
        readable(@cur_user, @cur_site).
        active
      @items = @items.in(category_id: category_ids) if @category.present?
    end
end
