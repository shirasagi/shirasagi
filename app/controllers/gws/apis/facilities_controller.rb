class Gws::Apis::FacilitiesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Facility::Item

  before_action :set_category

  private
    def set_category
      @groups = Gws::Facility::Category.site(@cur_site).reduce([]) do |ret, g|
        ret << [ "#{g.name}", g.id ]
      end.to_a

      @group = params[:s] ? params[:s][:group] : nil
      @group ||= @groups.first[1] if @groups.present?
    end

  public
    def index
      @multi = params[:single].blank?

      @items = @model.site(@cur_site).
        search(params[:s]).
        category_id(@group).
        page(params[:page]).per(50)
    end
end
