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

  def set_item
    @item ||= begin
      item = @items.find(params[:id])
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  public

  def index
    @categories = @categories.tree_sort
    @items = @items.search(@s).page(params[:page]).per(50)
  end

  def show
    if @cur_site.notice_toggle_by_read? && params[:toggled].blank? && !@item.browsed?(@cur_user)
      @item.set_browsed!(@cur_user)
      @item.reload
    end
    render
  end

  def toggle_browsed
    if @item.browsed?(@cur_user)
      @item.unset_browsed!(@cur_user)
    else
      @item.set_browsed!(@cur_user)
    end

    render_update true, location: { action: :show, toggled: 1 }
  rescue => e
    render_update false, render: { template: :show, toggled: 1 }
  end

  def print
    render :print, layout: 'ss/print'
  end
end
