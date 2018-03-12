class Gws::Report::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Report::File

  before_action :set_forms
  before_action :set_cur_form, only: %i[new create]
  before_action :set_cur_plan, only: %i[new create]
  before_action :set_search_params
  before_action :redirect_to_appropriate_state, only: %i[show]

  navi_view "gws/report/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_report_label || t('modules.gws/report'), action: :index]
    if params[:state].present?
      @crumbs << [t("gws/report.options.file_state.#{params[:state]}"), gws_report_files_path(state: params[:state])]
    end
  end

  def set_forms
    @forms ||= begin
      criteria = Gws::Report::Form.site(@cur_site)
      if params[:state] != 'preview'
        criteria = criteria.and_public
      end
      criteria = criteria.readable(@cur_user, site: @cur_site)
      criteria = criteria.order_by(order: 1, created: 1)
      criteria
    end
  end

  def set_cur_form
    return if params[:form_id].blank? || params[:form_id] == 'default'
    set_forms
    @cur_form ||= @forms.find(params[:form_id])
  end

  def set_cur_plan
    return if params[:plan_id].blank?
    @cur_plan ||= Gws::Schedule::Plan.site(@cur_site).find(params[:plan_id])
  end

  def set_search_params
    @s ||= begin
      s = OpenStruct.new params[:s]
      s.state = params[:state] if params[:state]
      s.cur_site = @cur_site
      s.cur_user = @cur_user
      s
    end
  end

  def set_items
    set_search_params
    @items ||= @model.site(@cur_site).search(@s).without_deleted
  end

  def set_item
    set_items
    @item ||= begin
      item = @items.find(params[:id])
      item.attributes = fix_params
      item
    end
    @cur_form ||= @item.form if @item.present?
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def pre_params
    ret = super

    set_cur_plan
    if @cur_plan
      ret[:schedule_ids] = [ @cur_plan.id.to_s ]
      ret[:member_ids] = @cur_plan.member_ids
      ret[:member_custom_group_ids] = @cur_plan.member_custom_group_ids
    end

    ret
  end

  def fix_params
    set_cur_form
    params = { cur_user: @cur_user, cur_site: @cur_site }
    params[:cur_form] = @cur_form if @cur_form
    params
  end

  def redirect_to_appropriate_state
    return if params[:state] != 'redirect'

    if @item.user_ids.include?(@cur_user.id) || (@item.group_ids & @cur_user.group_ids).present?
      if @item.public?
        state = 'sent'
      else
        state = 'closed'
      end
    elsif @item.member_ids.include?(@cur_user.id)
      state = 'inbox'
    else
      state = 'readable'
    end

    raise '404' if state.blank?
    redirect_to(state: state)
  end

  public

  def index
    set_items
    @items = @items.
      order_by(updated: -1, id: -1).
      page(params[:page]).per(50)
  end

  def show
    raise '403' unless @item.readable?(@cur_user, site: @cur_site) || @item.member?(@cur_user)
    render
  end

  def new
    if params[:form_id].blank?
      form_select
      return
    end

    @item = @model.new pre_params.merge(fix_params)
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_opts = { file: :new }
    render_opts[:layout] = false if request.xhr?
    render render_opts
  end

  def form_select
    set_forms
    @forms = @forms.search(params[:s]).page(params[:page]).per(50)
    render file: 'form_select'
  end

  def create
    @item = @model.new get_params
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    if @cur_form.present? && params[:custom].present?
      custom = params.require(:custom)
      new_column_values = @cur_form.build_column_values(custom)
      @item.update_column_values(new_column_values)
    end

    render_opts = { location: { action: :show, state: @item.state, id: @item } }
    render_create(@item.save, render_opts)
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    if @cur_form.present? && params[:custom].present?
      custom = params.require(:custom)
      new_column_values = @cur_form.build_column_values(custom)
      @item.update_column_values(new_column_values)
    end
    render_update @item.save
  end

  def print
    set_item
    render layout: 'ss/print'
  end

  def publish
    set_item
    if @item.public?
      redirect_to({ action: :show }, { notice: t('gws/report.notice.published') })
      return
    end
    return if request.get?

    @item.state = 'public'
    render_opts = { render: { file: :publish }, notice: t('gws/report.notice.published') }
    render_opts[:location] = gws_report_file_path(state: 'sent', id: @item)
    render_update @item.save, render_opts
  end

  def depublish
    set_item
    if @item.closed?
      redirect_to({ action: :show }, { notice: t('gws/report.notice.depublished') })
      return
    end
    return if request.get?

    @item.state = 'closed'
    render_opts = { render: { file: :depublish }, notice: t('gws/report.notice.depublished') }
    render_opts[:location] = gws_report_file_path(state: 'closed', id: @item)
    render_update @item.save, render_opts
  end

  def copy
    set_item
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    if request.get?
      @item.name = "[#{I18n.t('workflow.cloned_name_prefix')}] #{@item.name}".truncate(80)
      return
    end

    @new_item = @item.clone
    @new_item.attributes = get_params
    @new_item.schedule_ids = nil
    @new_item.member_ids = nil
    @new_item.member_custom_group_ids = nil
    @new_item.user_id = nil
    @new_item.user_uid = nil
    @new_item.user_name = nil
    @new_item.user_group_id = nil
    @new_item.user_group_name = nil
    @new_item.state = 'closed'
    @new_item.column_values.each do |column_value|
      if column_value.is_a?(Gws::Column::Value::FileUpload)
        column_value.in_clone_file = true
      end
    end

    result = @new_item.save
    if !result
      @item.errors[:base] += @new_item.errors.full_messages
    end

    render_opts = {}
    render_opts[:render] = { file: :copy }
    if result
      render_opts[:location] = gws_report_file_path(state: 'closed', id: @new_item)
    end
    render_update result, render_opts
  end
end
