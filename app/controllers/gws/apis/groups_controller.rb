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

  def set_items
    @items = @model.site(@cur_site).active
    @items = @items.search(search_params).
      reorder(name: 1).
      page(params[:page]).per(50)
  end

  public

  def index
    @multi = params[:single].blank?

    respond_to do |format|
      format.html do
        if search_params.blank?
          render Gws::Apis::GroupsComponent.new(cur_site: @cur_site, multi: @multi)
        else
          set_items
        end
      end
      format.json { set_items }
    end
  end
end
