class Garbage::CategoriesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Garbage::Node::Category

  prepend_view_path "app/views/cms/node/nodes"
  navi_view "garbage/categories/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "garbage/category" }
    end
end
