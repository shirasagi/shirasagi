class Garbage::NodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Garbage::Node::Base

  prepend_view_path "app/views/cms/node/nodes"
  navi_view "garbage/node/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "garbage/page" }
    end

  public
    def index
      redirect_to garbage_pages_path
      return
    end
end
