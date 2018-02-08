class Gws::Memo::ListsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::List

  navi_view 'gws/memo/messages/navi'

  before_action :set_category
  before_action :set_search_params

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('mongoid.models.gws/memo/list'), gws_memo_lists_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_category
    @categories = Gws::Memo::Category.site(@cur_site).readable(@cur_user, site: @cur_site).tree_sort
    if category_id = params[:category].presence
      @category ||= Gws::Memo::Category.site(@cur_site).readable(@cur_user, site: @cur_site).where(id: category_id).first
    end
  end

  def set_search_params
    @s = params[:s] || {}
    @s[:site] = @cur_site
    if @category
      @s[:category_id] = @category.id
    end
  end

  public

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(@s).
      page(params[:page]).per(50)
  end
end
