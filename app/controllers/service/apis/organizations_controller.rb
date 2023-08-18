class Service::Apis::OrganizationsController < ApplicationController
  include Service::ApiFilter

  model Gws::Group

  def index
    @multi = params[:single].blank?

    @search_params = params[:s]
    @search_params = @search_params.except(:state).delete_if { |k, v| v.blank? } if @search_params
    @search_params = @search_params.presence

    @items = @model.active.
      organizations.
      search(@search_params || {}).
      reorder(name: 1).
      page(params[:page]).per(50)
  end
end
