class Cms::Node::ImportPagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter
  include Workflow::PageFilter

  model Cms::ImportPage

  prepend_view_path "app/views/cms/pages"
  navi_view "cms/node/import_pages/navi"
  menu_view "cms/node/import_pages/menu"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

  public
    def convert
      set_item
      return if request.get?

      @item.attributes = get_params
      render_update @item.update, location: { action: :index }
    end
end
