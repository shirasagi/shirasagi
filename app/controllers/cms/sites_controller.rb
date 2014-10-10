class Cms::SitesController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter

  model Cms::Site

  navi_view "cms/main/navi"
  menu_view "cms/crud/resource_menu"

  private
    def set_crumbs
      @crumbs << [:"cms.site", action: :show]
    end

    def set_item
      @item = Cms::Site.find(@cur_site.id)
      @item.attributes = fix_params
    end

  public
    def edit
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
      render
    end

    def update
      @item.attributes = get_params
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
      render_update @item.update
    end
end
