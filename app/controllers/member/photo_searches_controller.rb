class Member::PhotoSearchesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Member::Node::PhotoSearch

  navi_view "cms/node/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "member/photo_search" }
    end
end
