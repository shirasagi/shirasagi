class Gws::HistoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::History

  navi_view "gws/main/conf_navi"

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/history", action: :index]
    end

  public
    def index
      raise '403' unless Gws::History.allowed?(:read, @cur_user, site: @cur_site)

      @items = @model.site(@cur_site).
        search(params[:s]).
        page(params[:page]).per(50)
    end
end
