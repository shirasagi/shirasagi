class Ezine::ColumnsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Ezine::Column

  navi_view "ezine/main/navi"

  private
    def fix_params
      { cur_site: @cur_site, cur_node: @cur_node }
    end

  public
    def index
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)

      @items = @model.site(@cur_site).node(@cur_node).
        order_by(order: 1).
        page(params[:page]).per(50)
    end
end
