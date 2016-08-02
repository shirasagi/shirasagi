class Opendata::MembersController < ApplicationController
  include Cms::BaseFilter

  model Opendata::Member

  append_view_path "app/views/cms/pages"
  navi_view "opendata/main/navi"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

  public
    def index
    end
end
