class Gws::Circular::AdminsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Circular::PostFilter

  navi_view "gws/circular/main/navi"

  private

  def set_cur_tab
    @cur_tab = [I18n.t('gws/circular.tabs.admin'), { action: :index, category: '-' }]
  end

  def set_search_params
    @s = OpenStruct.new params[:s]
    @s[:site] = @cur_site
    @s[:category_id] = @category.id if @category.present?
    @s[:sort] = @cur_site.circular_sort if @s[:sort].nil?
  end

  def set_items
    @items ||= @model.site(@cur_site).
      topic.
      without_deleted.
      allow(:read, @cur_user, site: @cur_site).
      search(@s).
      page(params[:page]).per(50).
      custom_order(@s.sort || 'due_date')
  end
end
