class Facility::SearchesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Facility::Node::Base

  prepend_view_path "app/views/cms/node/nodes"
  navi_view "facility/search/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "facility/node" }
    end
end
