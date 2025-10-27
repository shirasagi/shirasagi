class Gws::Notice::BackNumbersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Notice::ReadableFilter

  # '#redirection_calendar_params' is required
  helper Gws::Notice::PlanHelper

  before_action :set_item, only: [:show, :toggle_browsed, :print]

  model Gws::Notice::Post

  navi_view "gws/notice/main/navi"
  menu_view "gws/notice/readables/menu"

  private

  def check_permission
    # :use_gws_notice ＆サイト設定で表示になっている必要がある。
    super
    raise "404" unless @cur_site.notice_back_number_menu_visible?
  end

  def append_view_paths
    append_view_path "app/views/gws/notice/readables"
    super
  end

  def set_selected_group
    if params[:group].present? && params[:group] != '-'
      @selected_group = @cur_site.descendants.active.where(id: params[:group]).first
    end

    @selected_group ||= @cur_site
    @selected_group
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_notice_label || t('modules.gws/notice'), gws_notice_main_path]
    @crumbs << [@cur_site.notice_back_number_menu_label.presence || t('gws/notice.back_number'), url_for(action: :index, folder_id: '-', category_id: '-')]
  end

  def set_items
    @items = @model.site(@cur_site).and_public_but_after_close_date.
      readable(@cur_user, site: @cur_site).
      without_deleted
  end
end
