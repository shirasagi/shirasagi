class Facility::SearchesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Facility::Node::Search

  prepend_view_path "app/views/cms/node/nodes"
  navi_view "facility/main/navi"
  menu_view "facility/page/menu"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "facility/search" }
    end

  public
    def index
      redirect_to facility_pages_path
      return
    end
end
