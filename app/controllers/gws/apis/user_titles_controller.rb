class Gws::Apis::UserTitlesController < ApplicationController
  include Gws::ApiFilter

  model Gws::UserTitle


  def index
    @multi = params[:single].blank?

    @items = @model.active.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
