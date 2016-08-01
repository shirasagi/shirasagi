class Cms::Apis::SitesController < ApplicationController
  include Cms::ApiFilter

  model Cms::Site

  before_action :set_single

  private
    def set_single
      @single = params[:single].present?
      @multi = !@single
    end

  public
    def index
      @items = @model.
        allow(:read, @cur_user, site: @cur_site).
        search(params[:s]).
        order_by(_id: -1).
        page(params[:page]).per(50)
    end
end
