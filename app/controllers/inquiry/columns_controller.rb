class Inquiry::ColumnsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Inquiry::Column

  append_view_path "app/views/cms/pages"
  navi_view "inquiry/main/navi"

  private
    def fix_params
      { cur_site: @cur_site, node_id: @cur_node.id }
    end

  public
    def index
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)

      @items = @model.site(@cur_site).
        where(node_id: @cur_node.id).
        order_by(order: 1).
        page(params[:page]).per(50)
    end
end
