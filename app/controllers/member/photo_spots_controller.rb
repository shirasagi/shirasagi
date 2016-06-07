class Member::PhotoSpotsController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter
  include Workflow::PageFilter

  model Member::PhotoSpot

  append_view_path "app/views/cms/pages"
  navi_view "cms/node/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      @items = @model.site(@cur_site).
        allow(:read, @cur_user, site: @cur_site).
        order_by(released: -1).
        page(params[:page]).per(50)
    end
end
