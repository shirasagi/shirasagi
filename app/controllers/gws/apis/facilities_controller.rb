class Gws::Apis::FacilitiesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Facility::Item

  before_action :set_category

  private
    def set_category
      @groups = Gws::Facility::CategoryTraverser.build(@cur_site)
      @groups = @groups.flatten

      @group = params[:s] ? params[:s][:group].presence : nil
      if @group
        @group = Gws::Facility::Category.site(@cur_site).find(@group) rescue nil
      end
    end

  public
    def index
      @multi = params[:single].blank?

      @items = @model.site(@cur_site).
        category_id(@group.try(:id)).
        readable(@cur_user).
        reservable(@cur_user).
        active.
        search(params[:s]).
        page(params[:page]).per(50)
    end
end
