class Gws::Tabular::Gws::TrashSpacesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Tabular::Space

  navi_view "gws/tabular/gws/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [ t('modules.gws/tabular'), gws_tabular_gws_main_path ]
    @crumbs << [ t('mongoid.models.gws/tabular/space'), gws_tabular_gws_spaces_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def base_items
    @base_items ||= begin
      criteria = @model.site(@cur_site)
      criteria = criteria.only_deleted
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria = criteria.search(params[:s])
      criteria
    end
  end

  public

  def index
    @items = base_items.page(params[:page]).per(SS.max_items_per_page)
  end
end
