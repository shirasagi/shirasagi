class Gws::Schedule::FacilitiesController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  before_action :set_category, only: :index

  private
    def set_category
      @categories = Gws::Facility::CategoryTraverser.build(@cur_site, @cur_user)
      @categories = @categories.flatten

      @category = params[:s] ? params[:s][:category] : nil
      if @category.present?
        @category = Gws::Facility::Category.site(@cur_site).find(@category) rescue nil
      end

      @category ||= begin
        c = @categories.find { |c| c.id.present? }
        c = Gws::Facility::Category.site(@cur_site).find(c.id) rescue nil
        c
      end
    end

    def category_ids
      return if @category.blank?
      ids = Gws::Facility::Category.site(@cur_site).where(name: /^#{Regexp.escape(@category.name)}\//).pluck(:id)
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
