class Inquiry::ResultsController < ApplicationController
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

      @cur_node = @cur_node.becomes_with_route
      @columns = @cur_node.columns.order_by(order: 1)
      @aggregation = @cur_node.aggregate_select_columns
    end
end
