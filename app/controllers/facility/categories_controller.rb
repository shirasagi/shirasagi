class Facility::CategoriesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Facility::Node::Category

  prepend_view_path "app/views/cms/node/nodes"
  navi_view "facility/categories/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "facility/category" }
    end
end
