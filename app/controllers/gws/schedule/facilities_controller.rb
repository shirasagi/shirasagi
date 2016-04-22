class Gws::Schedule::FacilitiesController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  before_action :set_category, only: :index

  private
    def set_category
      @categories = Gws::Facility::CategoryTraverser.build(@cur_site)
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

  public
    def index
      @items = Gws::Facility::Item.site(@cur_site).
        category_id(@category).
        readable(@cur_user, @cur_site).
        active
    end
end
