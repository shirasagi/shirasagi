class Gws::Survey::EditablesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  before_action :set_categories
  before_action :set_category
  before_action :set_search_params
  before_action :set_items
  before_action :set_item, only: [:show, :edit, :update, :soft_delete, :move, :publish, :depublish]
  before_action :set_selected_items, only: [:destroy_all, :soft_delete_all]

  model Gws::Survey::Form

  navi_view "gws/survey/main/navi"

  append_view_path "app/views/gws/survey/main"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_survey_label || t('modules.gws/survey'), gws_survey_main_path]
    @crumbs << [t('ss.navi.editable'), action: :index, folder_id: '-', category_id: '-']
  end

  def pre_params
    { due_date: Time.zone.now.beginning_of_hour + 1.hour + @cur_site.survey_default_due_date.day }
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_categories
    @categories ||= Gws::Survey::Category.site(@cur_site).readable(@cur_user, site: @cur_site)
  end

  def set_category
    return if params[:category_id].blank? || params[:category_id] == '-'
    @category ||= @categories.find(id: params[:category_id])
    raise '403' unless @category.readable?(@cur_user) || @category.allowed?(:read, @cur_user, site: @cur_site)
  end

  def set_search_params
    @s = params[:s].presence || {}
    if @folder.present?
      @s[:folder_ids] = [ @folder.id ]
      @s[:folder_ids] += @folder.folders.for_post_editor(@cur_site, @cur_user).pluck(:id)
    end

    @s[:category_id] = @category.id if @category.present?
  end

  def set_items
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      without_deleted.
      search(@s)
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

  def set_selected_items
    ids = params[:ids]
    raise "400" unless ids
    ids = ids.split(",") if ids.is_a?(String)
    @items = @items.in(id: ids)
    raise "400" unless @items.present?
  end

  public

  def index
    @categories = @categories.tree_sort
    @items = @items.order_by(updated: -1, id: 1).page(params[:page]).per(50)
  end

  def publish
    if @item.public?
      redirect_to({ action: :show }, { notice: t('gws/workflow.notice.published') })
      return
    end
    return if request.get?

    @item.attributes = get_params
    @item.state = 'public'
    render_opts = { render: { file: :publish }, notice: t('gws/workflow.notice.published') }
    render_update @item.save, render_opts
  end

  def depublish
    if @item.closed?
      redirect_to({ action: :show }, { notice: t('gws/workflow.notice.depublished') })
      return
    end
    return if request.get?

    @item.state = 'closed'
    render_opts = { render: { file: :depublish }, notice: t('gws/workflow.notice.depublished') }
    render_update @item.save, render_opts
  end
end
