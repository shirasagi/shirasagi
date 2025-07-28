class Gws::Tabular::Gws::TrashFormsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Tabular::Form

  navi_view "gws/tabular/gws/main/conf_navi"

  helper_method :cur_space

  private

  def cur_space
    @cur_space ||= begin
      criteria = Gws::Tabular::Space.site(@cur_site)
      criteria = criteria.without_deleted
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria.find(params[:space])
    end
  end

  def set_crumbs
    @crumbs << [ t('modules.gws/tabular'), gws_tabular_gws_main_path ]
    @crumbs << [ t('mongoid.models.gws/tabular/space'), gws_tabular_gws_spaces_path ]
    @crumbs << [ cur_space.name, gws_tabular_gws_space_path(id: cur_space) ]
    @crumbs << [ t('mongoid.models.gws/tabular/form'), gws_tabular_gws_forms_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_space: cur_space }
  end

  def respond_404_if_item_is_public
    raise "404" if @item.public?
  end

  def base_items
    @base_items ||= begin
      criteria = @model.site(@cur_site)
      criteria = criteria.space(cur_space)
      criteria = criteria.only_deleted
      criteria = criteria.allow(:read, @cur_user, site: @cur_site)
      criteria = criteria.search(params[:s])
      criteria
    end
  end

  public

  def index
    # raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)
    @items = base_items.page(params[:page]).per(SS.max_items_per_page)
  end
end
