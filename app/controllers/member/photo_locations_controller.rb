class Member::PhotoLocationsController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Member::Node::PhotoLocation

  navi_view "cms/node/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "member/photo_location" }
    end
end
