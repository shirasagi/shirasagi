class Cms::Node::ConfsController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Cms::Node

  navi_view "cms/node/main/navi"

  private
    def set_item
      @item = @cur_node
      @item.attributes = fix_params
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node.parent }
    end

    def redirect_url
      { action: :show }
    end

    def redirect_url_on_destroy
      @item.parent ? view_context.contents_path(@item.parent) : cms_nodes_path
    end

  public
    def destroy
      raise "403" unless @item.allowed?(:delete, @cur_user)
      render_destroy @item.destroy, location: redirect_url_on_destroy
    end
end
