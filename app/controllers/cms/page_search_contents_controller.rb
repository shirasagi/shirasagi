class Cms::PageSearchContentsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  navi_view "cms/main/navi"
  menu_view nil
  model Cms::PageSearch

  before_action -> { @list_head_search = true }, only: :show

  private
    def set_crumbs
      set_item
      @crumbs << [ @item.name, action: :show ]
    end

    def fix_params
      { cur_site: @cur_site, cur_user: @cur_user }
    end
end
