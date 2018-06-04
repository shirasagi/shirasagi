class Gws::Notice::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Notice::Category

  navi_view "gws/notice/main/navi"

  def index
    #raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

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
    @crumbs << [t('modules.gws/notice'), gws_notice_main_path]
    @crumbs << [t('mongoid.models.gws/board/category'), gws_notice_categories_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
