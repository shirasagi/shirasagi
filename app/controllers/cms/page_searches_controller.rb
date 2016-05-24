class Cms::PageSearchesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::PageSearch
  navi_view "cms/main/conf_navi"

  private
    def fix_params
      { cur_site: @cur_site, cur_user: @cur_user }
    end

    def pre_params
      if params[:item].present?
        params.require(:item).permit(permit_fields)
      else
        {}
      end
    end

  public
    def search
      set_item
    end
end
