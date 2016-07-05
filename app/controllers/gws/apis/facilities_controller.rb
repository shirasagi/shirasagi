class Gws::Apis::FacilitiesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Facility::Item

  before_action :set_category

  private
    def category_criteria
      Gws::Facility::Category.site(@cur_site).readable(@cur_user, @cur_site)
    end

    def set_category
      @categories = category_criteria.tree_sort

      category_id = params.dig(:s, :category)
      if category_id
        @category = category_criteria.find(category_id) rescue nil
      end
    end

    def category_ids
      return if @category.blank?
      ids = category_criteria.where(name: /^#{Regexp.escape(@category.name)}\//).pluck(:id)
      ids << @category.id
    end

  public
    def index
      @multi = params[:single].blank?

      @items = @model.site(@cur_site).
        readable(@cur_user, @cur_site).
        reservable(@cur_user).
        active.
        search(params[:s])
      @items = @items.in(category_id: category_ids) if @category.present?
      @items = @items.page(params[:page]).per(50)
    end
end
