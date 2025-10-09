class Cms::Apis::GroupsController < ApplicationController
  include Cms::ApiFilter

  model Cms::Group

  private

  def search_params
    @search_params ||= begin
      search_params = params[:s]
      search_params = search_params.except(:state).delete_if { |k, v| v.blank? } if search_params
      search_params.presence
    end
  end

  def set_items
    @items ||= begin
      criteria = @model.site(@cur_site).active
      criteria = criteria.search(search_params)
      criteria = criteria.reorder(name: 1, order: 1, id: 1)
      criteria = criteria.page(params[:page]).per(SS.max_items_per_page)
      criteria
    end
  end

  public

  def index
    @single = params[:single].present?
    @multi = !@single

    if search_params.blank?
      render Cms::Apis::GroupsComponent.new(cur_site: @cur_site, multi: @multi)
    else
      set_items
    end
  end
end
