class Gws::Notice::ReadablesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Notice::ReadableFilter

  helper Gws::Notice::PlanHelper

  before_action :set_item, only: [:show, :toggle_browsed, :print]

  model Gws::Notice::Post

  navi_view "gws/notice/main/navi"

  private

  def set_selected_group
    if params[:group].present? && params[:group] != '-'
      @selected_group = @cur_site.descendants.active.where(id: params[:group]).first
    end

    @selected_group ||= @cur_site
    @selected_group
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_notice_label || t('modules.gws/notice'), gws_notice_main_path]
    @crumbs << [t('ss.navi.readable'), action: :index, folder_id: '-', category_id: '-']
  end
end
