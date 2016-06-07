class Member::PhotoCategoriesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Member::Node::PhotoCategory

  navi_view "cms/node/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "member/photo_category" }
    end
end
