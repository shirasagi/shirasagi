class Gws::UserTitlesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::UserTitle

  navi_view "gws/main/conf_navi"

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.ss/user_title", gws_user_titles_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

  public
    def index
      @items = @model.site(@cur_site).
        allow(:read, @cur_user, site: @cur_site).
        search(params[:s]).
        page(params[:page]).per(50)
    end
end
