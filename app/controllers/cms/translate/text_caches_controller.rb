class Cms::Translate::TextCachesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model ::Translate::TextCache
  navi_view "cms/translate/main/navi"

  private

  def fix_params
    { cur_site: @cur_site, api: @cur_site.translate_api, update_state: "manually" }
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    set_items
    @items = @items.where(api: @cur_site.translate_api).search(params[:s])
      .page(params[:page]).per(100)
  end
end
