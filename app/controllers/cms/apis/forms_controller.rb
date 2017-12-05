class Cms::Apis::FormsController < ApplicationController
  include Cms::ApiFilter

  model Cms::Form

  def index
    @single = params[:single].present?
    @multi = !@single

    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      order_by(_id: -1).
      page(params[:page]).per(50)
  end
end
