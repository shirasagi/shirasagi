class Gws::Share::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/share/settings/navi"

  model Gws::Share::Category

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/share/group_setting", gws_share_files_path]
      @crumbs << [:"mongoid.models.gws/share/group_setting/category", gws_share_files_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end
end
