class Gws::Workflow::FilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Workflow::File

  before_action :set_forms
  before_action :set_cur_form, only: %i[new create]
  before_action :set_search_params

  navi_view "gws/workflow/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_workflow_label || t("modules.gws/workflow"), action: :index]
  end

  def set_forms
    @forms ||= begin
      criteria = Gws::Workflow::Form.site(@cur_site)
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

  def set_item
    super
    @cur_form ||= @item.form if @item.present?
  end

  def fix_params
    set_cur_form
    params = { cur_user: @cur_user, cur_site: @cur_site, state: 'closed' }
    params[:cur_form] = @cur_form if @cur_form
    params
  end

  def set_search_params
    @s = OpenStruct.new params[:s]
    @s.state = params[:state] if params[:state]
    @s.cur_site = @cur_site
    @s.cur_user = @cur_user
  end

  public

  def index
    @items = @model.site(@cur_site).without_deleted.
      search(@s).
      page(params[:page]).per(50)
  end

  def show
    raise '403' unless @item.readable?(@cur_user, site: @cur_site)
    render
  end

  def new
    if params[:form_id].blank?
      form_select
      return
    end

    @item = @model.new pre_params.merge(fix_params)
    raise '403' unless @item.editable?(@cur_user, site: @cur_site)
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
    if @cur_form.present? && params[:custom].present?
      custom = params.require(:custom)
      new_column_values = @cur_form.build_column_values(custom)
      @item.update_column_values(new_column_values)
    end
    raise '403' unless @item.editable?(@cur_user, site: @cur_site)
    render_create @item.save
  end

  def edit
    raise '403' unless @item.editable?(@cur_user, site: @cur_site)
    if @item.is_a?(Cms::Addon::EditLock)
      unless @item.acquire_lock
        redirect_to action: :lock
        return
      end
    end
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    if @cur_form.present? && params[:custom].present?
      custom = params.require(:custom)
      new_column_values = @cur_form.build_column_values(custom)
      @item.update_column_values(new_column_values)
    end
    raise '403' unless @item.editable?(@cur_user, site: @cur_site)
    render_update @item.save
  end

  def delete
    raise '403' unless @item.destroyable?(@cur_user, site: @cur_site)
    render
  end

  def destroy
    raise '403' unless @item.destroyable?(@cur_user, site: @cur_site)
    render_destroy @item.destroy
  end

  def destroy_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.destroyable?(@cur_user, site: @cur_site)
        next if item.destroy
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def request_cancel
    set_item
    raise '403' unless @item.allowed?(:edit, @cur_user)

    return if request.get?

    @item.state = 'closed'
    @item.workflow_user_id = nil
    @item.workflow_state = nil
    @item.workflow_comment = nil
    @item.workflow_approvers = nil
    @item.workflow_required_counts = nil

    render_opts = { render: { file: :request_cancel }, notice: t('workflow.notice.request_cancelled') }
    render_update @item.save, render_opts
  end

  def print
    set_item
    render layout: 'ss/print'
  end

  def copy
    set_item
    raise '403' unless @item.allowed?(:edit, @cur_user)

    if request.get?
      @item.name = "[#{I18n.t('workflow.cloned_name_prefix')}] #{@item.name}".truncate(80)
      return
    end

    @new_item = @item.clone
    @new_item.attributes = get_params
    @new_item.in_clone_file = true
    @new_item.workflow_user_id = nil
    @new_item.workflow_state = nil
    @new_item.workflow_comment = nil
    @new_item.workflow_approvers = nil
    @new_item.workflow_required_counts = nil
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
      render_opts[:location] = gws_workflow_file_path(state: 'all', id: @new_item)
    end
    render_update result, render_opts
  end
end
