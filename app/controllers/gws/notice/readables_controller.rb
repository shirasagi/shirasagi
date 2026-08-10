class Gws::Notice::ReadablesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Notice::ReadableFilter

  helper Gws::Notice::PlanHelper

  before_action :set_item, only: [:show, :toggle_browsed, :print]

  model Gws::Notice::Post

  helper_method :move_to_prev_tag, :move_to_next_tag

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

  def move_to_prev_tag
    label = t('gws/memo/message.links.prev')
    prev_path = @prev_id ? url_for(action: :show, id: @prev_id) : "#"
    css_classes = %w(prev)
    unless @prev_id
      css_classes << "inactive"
    end

    view_context.tag.div(class: css_classes) do
      view_context.link_to(prev_path, title: label, aria: { label: label }) do
        view_context.tag.span("arrow_circle_left", class: "material-icons-outlined")
      end
    end
  end

  def move_to_next_tag
    label = t('gws/memo/message.links.next')
    next_path = @next_id ? url_for(action: :show, id: @next_id) : "#"
    css_classes = %w(next)
    unless @next_id
      css_classes << "inactive"
    end

    view_context.tag.div(class: css_classes) do
      view_context.link_to(next_path, title: label, aria: { label: label }) do
        view_context.tag.span("arrow_circle_right", class: "material-icons-outlined")
      end
    end
  end

  public

  def index
    @categories = @categories.tree_sort
    @items = @items.search(@s).reorder(released: -1, id: -1).page(params[:page]).per(50)

    id_list = []
    @items.each do |item|
      id_list << item.id.to_s
    end
    gws_notice_id_list_session = session[:gws_notice_id_list]
    gws_notice_id_list_session ||= {}
    gws_notice_id_list_session['id_list'] = id_list
    if params[:s]
      gws_notice_id_list_session['search'] = params[:s].to_unsafe_h
    else
      gws_notice_id_list_session['search'] = nil
    end
    gws_notice_id_list_session['page'] = params[:page]
    session[:gws_notice_id_list] = gws_notice_id_list_session
  end

  def show
    if @cur_site.notice_toggle_by_read? && params[:toggled].blank? && !@item.browsed?(@cur_user)
      @item.set_browsed!(@cur_user)
      @item.reload
    end

    # 念の為初期化する（本アクションで設定するメンバー変数一覧を明示的に示す意図もある）
    @id_list = nil
    @id_index = nil
    @search = nil
    @page = nil
    @prev_id = nil
    @next_id = nil
    gws_notice_id_list_session = session[:gws_notice_id_list]
    return if gws_notice_id_list_session.blank?

    @id_list = gws_notice_id_list_session['id_list']
    @search = gws_notice_id_list_session['search']
    @page = gws_notice_id_list_session['page']
    return if @id_list.blank?

    @id_index = @id_list.index(@item.id.to_s)
    return if @id_index.blank?

    if @id_index > 0
      @prev_id = @id_list[@id_index - 1]
    end
    if @id_index < @id_list.size
      @next_id = @id_list[@id_index + 1]
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
