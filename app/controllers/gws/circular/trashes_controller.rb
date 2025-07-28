class Gws::Circular::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Circular::PostFilter

  navi_view "gws/circular/main/navi"

  private

  def set_cur_tab
    @cur_tab = [I18n.t('gws/circular.tabs.trash'), { action: :index, category: '-' }]
  end

  def set_search_params
    @s = OpenStruct.new params[:s]
    @s[:site] = @cur_site
    @s[:category_id] = @category.id if @category.present?
  end

  def set_items
    @items ||= @model.site(@cur_site).
      topic.
      only_deleted.
      allow(:trash, @cur_user, site: @cur_site).
      search(@s).
      page(params[:page]).per(50)
  end
end
