class Chat::IntentsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Chat::Intent

  navi_view "cms/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [t('chat.bot'), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    set_items
    @items = @items.search(params[:s]).
      order_by(updated: -1).
      page(params[:page]).
      per(50)
  end
end
