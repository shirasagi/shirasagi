class Chorg::RevisionsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Chorg::Revision

  navi_view "cms/main/navi"

  private
    def set_crumbs
      @crumbs << [:"chorg.revision", action: :index]
    end

    def fix_params
      { cur_site: @cur_site }
    end
end
