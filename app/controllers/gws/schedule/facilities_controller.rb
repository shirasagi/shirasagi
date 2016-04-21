class Gws::Schedule::FacilitiesController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  before_action :set_category, only: :index

  private
    def set_category
      @categories = Gws::Facility::Category.site(@cur_site).reduce([]) do |ret, g|
        ret << [ "- #{g.name}", g.id ]
      end.to_a

      @category = params[:s] ? params[:s][:category] : nil
      @category ||= @categories.first[1] if @categories.present?
    end

  public
    def index
      @items = Gws::Facility::Item.site(@cur_site).
        category_id(@category).
        readable(@cur_user, @cur_site).
        active
    end
end
