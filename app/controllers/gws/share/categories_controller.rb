class Gws::Share::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/share/settings/navi"

  model Gws::Share::Category

  private
    def set_crumbs
      @crumbs << [:"modules.settings.gws/share", gws_share_files_path]
      @crumbs << [:"modules.settings.gws/share/category", gws_share_files_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end
end
