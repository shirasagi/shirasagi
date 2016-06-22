class Cms::ThemeTemplatesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::ThemeTemplate
  navi_view "cms/main/conf_navi"

  private
    def set_crumbs
      @crumbs << [:"cms.theme_template", action: :index]
    end

    def fix_params
      { cur_site: @cur_site }
    end
end
