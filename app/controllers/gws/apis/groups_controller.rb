class Gws::Apis::GroupsController < ApplicationController
  include Gws::ApiFilter

  model Gws::Group

  def index
    @single = params[:single].present?
    @multi = !@single
    @items = @model.site(@cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
