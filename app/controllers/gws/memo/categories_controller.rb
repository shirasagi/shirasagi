class Gws::Memo::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view 'gws/memo/messages/navi'

  model Gws::Memo::Category

  def index
    raise '403' unless @model.allowed?(:read, @cur_user, site: @cur_site)

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
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('mongoid.models.gws/memo/category'), gws_memo_categories_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end
end
