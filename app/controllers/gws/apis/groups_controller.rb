class Gws::Apis::GroupsController < ApplicationController
  include Gws::ApiFilter

  model Gws::Group

  private

  def search_params
    @search_params ||= begin
      search_params = params[:s]
      search_params = search_params.except(:state).delete_if { |k, v| v.blank? } if search_params
      search_params.presence
    end
  end

  public

  def index
    @multi = params[:single].blank?

    if search_params.blank? && params[:format].blank?
      render Gws::Apis::GroupsComponent.new(cur_site: @cur_site, multi: @multi)
      return
    end

    @items = @model.site(@cur_site).active
    @items = @items.search(search_params).
      reorder(name: 1).
      page(params[:page]).per(50)
  end
end
