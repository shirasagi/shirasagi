class Gws::Apis::GroupsController < ApplicationController
  include Gws::ApiFilter

  model Gws::Group

  def index
    @multi = params[:single].blank?

    @items = @model.site(@cur_site).
      active.
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
