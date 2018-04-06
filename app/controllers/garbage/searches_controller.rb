class Garbage::SearchesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Garbage::Node::Base

  prepend_view_path "app/views/cms/node/nodes"
  navi_view "facility/search/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "garbage/node" }
    end
end
