class Gws::Affair2::Apis::DutyNoticesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Affair2::DutyNotice

  def index
    @multi = params[:single].blank?

    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
