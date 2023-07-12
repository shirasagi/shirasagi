class Gws::Notice::CalendarsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Notice::ReadableFilter

  helper Gws::Notice::PlanHelper

  model Gws::Notice::Post

  navi_view "gws/notice/main/navi"
  menu_view nil

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_notice_label || t('modules.gws/notice'), gws_notice_main_path]
    @crumbs << [t('ss.navi.calendar'), action: :index, folder_id: '-', category_id: '-']
  end

  # override Gws::BaseFilter#set_gws_assets
  def set_gws_assets
    super
    javascript("gws/calendar", defer: true)
  end

  def set_items
    super
    @items = @items.exists_term
  end

  public

  def index
    @categories = @categories.reorder(order: 1, name: 1)
  end

  def events
    @items = @items.search(@s)
    @items = @items.reorder(released: -1)
  end

  def print
    @portrait = 'horizontal'
    render template: 'print', layout: 'ss/print'
  end
end
