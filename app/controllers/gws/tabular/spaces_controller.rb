class Gws::Tabular::SpacesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Tabular::Space

  navi_view "gws/main/navi"
  menu_view nil

  private

  def spaces
    @spaces ||= begin
      criteria = Gws::Tabular::Space.site(@cur_site)
      criteria = criteria.and_public
      criteria = criteria.without_deleted
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria.only(:id, :site_id, :i18n_name, :order, :updated)
    end
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_tabular_label || t('modules.gws/tabular'), gws_tabular_spaces_path]
  end

  public

  def index
    raise "404" unless @cur_site.menu_tabular_visible?
    raise "403" unless Gws.module_usable?(:tabular, @cur_site, @cur_user)

    @items = spaces.search(params[:s]).reorder(order: 1, id: 1).page(params[:page]).per(SS.max_items_per_page)
  end
end
