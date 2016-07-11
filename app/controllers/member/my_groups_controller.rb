class Member::MyGroupsController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Member::Node::Base

  navi_view "cms/node/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def redirect_url
      { action: :index }
    end
end
