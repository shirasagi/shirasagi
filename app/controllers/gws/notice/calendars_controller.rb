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
    label = @cur_site.notice_calendar_menu_label.presence || t('ss.navi.calendar')
    @crumbs << [label, url_for(action: :index, folder_id: '-', category_id: '-')]
  end

  # override Gws::BaseFilter#set_gws_assets
  def set_gws_assets
    super
    javascript("gws/calendar", defer: true)
  end

  def set_items
    criteria = @model.all.site(@cur_site)
    criteria = criteria.readable(@cur_user, site: @cur_site)
    criteria = criteria.without_deleted
    if @s[:content_types].try(:include?, "back_numbers") && @cur_site.notice_back_number_menu_visible?
      criteria = criteria.where(state: { "$in" => @model.public_states })
    else
      criteria = criteria.and_public
    end
    @items = criteria.exists_term
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
