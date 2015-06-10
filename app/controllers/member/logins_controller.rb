class Member::LoginsController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Member::Node::Login

  navi_view "cms/node/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def pre_params
      { route: "member/login" }
    end

  public
    def index
    end
end
