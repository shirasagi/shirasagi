class Ads::BannersController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Ads::Banner

  prepend_view_path "app/views/cms/pages"
  navi_view "ads/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "ads/banner" }
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

      @items = @model.site(@cur_site).node(@cur_node).
        allow(:read, @cur_user).
        search(params[:s]).
        order_by(order: 1).
        page(params[:page]).per(50)
    end
end
