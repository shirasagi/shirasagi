class Gws::Survey::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Survey::Category

  navi_view "gws/survey/main/navi"

  def index
    @search_params = params[:s]
    @search_params = @search_params.delete_if { |k, v| v.blank? } if @search_params
    @search_params = @search_params.presence

    @items = @model.site(@cur_site).allow(:read, @cur_user, site: @cur_site)
    if @search_params
      @items = @items.search(@search_params).page(params[:page]).per(50)
    else
      @items = @items.tree_sort
    end
  end

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_survey_label || t('modules.gws/survey'), gws_survey_main_path]
    @crumbs << [t('gws.category'), gws_survey_categories_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
