class Gws::SitesController < ApplicationController
  include Gws::BaseFilter
  include SS::CrudFilter

  model Gws::Group

  navi_view "gws/main/conf_navi"
  menu_view nil

  private
    def set_crumbs
      @crumbs << [:"gws.site_info", action: :show]
    end

    def set_item
      @item = Gws::Group.find(@cur_site.id)
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
