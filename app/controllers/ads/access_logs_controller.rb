class Ads::AccessLogsController < ApplicationController
  include Cms::BaseFilter

  model Ads::AccessLog

  navi_view "ads/main/navi"

  public
    def index
      @items = @model.site(@cur_site).
        where(node_id: @cur_node.id).
        order_by(date: -1).
        page(params[:page]).per(50)
    end
end
