class Cms::Node::ImportNodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Cms::Node::ImportNode

  navi_view "cms/node/import_pages/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "cms/import_node" }
    end

    def redirect_url
      { action: :show, id: @item.id }
    end
end
