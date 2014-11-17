class Facility::NodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Facility::Node::Base

  prepend_view_path "app/views/cms/node/nodes"
  navi_view "facility/node/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "facility/page" }
    end

  public
    def index
      redirect_to facility_pages_path
      return
    end
end
