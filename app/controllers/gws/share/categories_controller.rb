class Gws::Share::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/main/conf_navi"

  model Gws::Share::Category

  private
    def set_crumbs
      @crumbs << [:"modules.gws/share.", gws_share_files_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end
end
