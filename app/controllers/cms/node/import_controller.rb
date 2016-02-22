class Cms::Node::ImportController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Node::ImportNode

  navi_view "cms/node/import_pages/navi"
  menu_view nil

  before_action :set_item

  def import
    @item.attributes = get_params
    @item.cur_site = @cur_site
    result = @item.import
    flash.now[:notice] = t("views.notice.saved") if !result && @item.imported > 0
    render_create result, location: redirect_url, render: { file: :index }
  end

  private
    def set_item
      @item = @cur_node.becomes_with_route("cms/import_node")
    end

    def redirect_url
      node_import_pages_path(cid: @cur_node)
    end
end
