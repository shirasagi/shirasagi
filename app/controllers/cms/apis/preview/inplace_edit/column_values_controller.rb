class Cms::Apis::Preview::InplaceEdit::ColumnValuesController < ApplicationController
  include Cms::ApiFilter
  include Cms::InplaceEditFilter

  model Cms::Column::Value::Base

  layout "ss/ajax_in_iframe"

  before_action :set_inplace_mode
  before_action :set_item
  before_action :set_column, only: %i[new]
  before_action :set_column_and_value, only: %i[edit update destroy move_up move_down move_at]

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_inplace_mode
    @inplace_mode = true
  end

  def set_item
    @item = @cur_page = Cms::Page.site(@cur_site).find(params[:page_id]).becomes_with_route
    @item.attributes = fix_params
    raise "404" if !@item.respond_to?(:form) || !@item.respond_to?(:column_values)

    @model = @item.class
  end

  def set_column
    @cur_column = @item.form.columns.find(params[:column_id].to_s)
  end

  def set_column_and_value
    @cur_column_value = @item.column_values.find(params[:id])

    @cur_column = @cur_column_value.column
    raise "404" if @cur_column.blank?
  end

  def new_column_value
    safe_params = params.require(:item).permit(@model.permit_params)
    column_value_param = safe_params[:column_values].first
    column_value_param[:order] = @item.column_values.present? ? @item.column_values.max(:order) + 1 : 0
    @cur_column_value = @item.column_values.build(column_value_param)
    @cur_column = @cur_column_value.column
  end

  def create_with_overwrite
    new_column_value
    result = @item.save

    location = { action: :edit, id: @cur_column_value }
    if result
      flash["cms.preview.notice"] = t("ss.notice.saved")
    end
    render_create result, location: location, render: { file: :new, status: :unprocessable_entity }
  end

  def create_as_branch
    safe_params = params.require(:item).permit(@model.permit_params)
    column_value_param = safe_params[:column_values].first
    column_value_param[:order] = @item.column_values.present? ? @item.column_values.max(:order) + 1 : 0

    if @item.branches.present?
      @cur_column_value = @item.column_values.build(column_value_param)
      @cur_column = @cur_column_value.column

      @cur_column_value.errors.add(:base, :branch_is_already_existed)
      render_create_as_branch false
      return
    end

    @item.cur_site = @cur_site
    @item.cur_node = @item.parent if @item.parent
    @item.cur_user = @cur_user
    branch = @item.new_clone
    branch.master = @item

    @cur_column_value = branch.column_values.build(column_value_param)
    @cur_column = @cur_column_value.column

    result = branch.save

    if !result
      @cur_column_value.errors.messages[:base] += branch.errors.full_messages
      render_create_as_branch false
      return
    end

    path_params = { path: branch.filename, anchor: "inplace" }
    path_params[:preview_date] = params[:preview_date].to_s if params[:preview_date].present?
    location = cms_preview_path(path_params)

    render_create_as_branch result, location
  end

  def render_create_as_branch(result, location = nil)
    if result && location
      flash["cms.preview.notice"] = I18n.t("workflow.notice.created_branch_page")
      render json: { location: location }, status: :ok, content_type: json_content_type
    else
      render file: :new, status: :unprocessable_entity
    end
  end

  def save_with_overwrite
    render_opts = {
      location: { action: :edit },
      render: { file: :edit, status: :unprocessable_entity }
    }

    result = @item.save
    flash["cms.preview.notice"] = t("ss.notice.saved") if result
    render_update result, render_opts
  end

  def save_as_branch
    if @item.branches.present?
      @cur_column_value.errors.add :base, :branch_is_already_existed
      render_save_as_branch false
      return
    end

    @item.cur_site = @cur_site
    @item.cur_node = @item.parent if @item.parent
    @item.cur_user = @cur_user
    branch = @item.new_clone
    branch.master = @item
    result = branch.save
    if !result
      @cur_column_value.errors.messages[:base] += branch.errors.full_messages
      render_save_as_branch false
      return
    end

    path_params = { path: branch.filename, anchor: "inplace" }
    path_params[:preview_date] = params[:preview_date].to_s if params[:preview_date].present?
    location = cms_preview_path(path_params)
    render_save_as_branch result, location
  end

  def render_save_as_branch(result, location = nil)
    if result && location
      flash["cms.preview.notice"] = I18n.t("workflow.notice.created_branch_page")
      render json: { location: location }, status: :ok, content_type: json_content_type
    else
      render file: :edit, status: :unprocessable_entity
    end
  end

  def destroy_with_overwrite
    result = @cur_column_value.destroy
    if result
      respond_to do |format|
        format.html { head :no_content }
        format.json { head :no_content }
      end
    else
      render json: @item.errors.full_messages, status: :unprocessable_entity
    end
  end

  def destroy_as_branch
    if @item.branches.present?
      @item.errors.add :base, :branch_is_already_existed
      render_save_as_branch false
      return
    end

    @item.cur_site = @cur_site
    @item.cur_node = @item.parent if @item.parent
    @item.cur_user = @cur_user
    branch = @item.new_clone
    branch.master = @item

    id = params[:id].to_s
    @cur_column_value = branch.column_values.to_a.find { |item| item.origin_id.to_s == id }
    @cur_column = @cur_column_value.column

    @cur_column_value.destroy
    result = branch.save

    path_params = { path: branch.filename, anchor: "inplace" }
    path_params[:preview_date] = params[:preview_date].to_s if params[:preview_date].present?
    location = cms_preview_path(path_params)
    render_destroy_as_branch result, location
  end

  def render_destroy_as_branch(result, location = nil)
    if result && location
      flash["cms.preview.notice"] = I18n.t("workflow.notice.created_branch_page")
      render json: { location: location }, status: :ok, content_type: json_content_type
    else
      render json: @item.errors.full_messages, status: :unprocessable_entity
    end
  end

  def render_move(result)
    if result
      json = Hash[@item.column_values.map { |value| [ value.id, value.order ] }]
      render json: json, status: :ok, content_type: json_content_type
    else
      render json: @item.errors.full_messages, status: :unprocessable_entity
    end
  end

  def render_move_as_branch(result, branch)
    if result
      path_params = { path: branch.filename, anchor: "inplace" }
      path_params[:preview_date] = params[:preview_date].to_s if params[:preview_date].present?
      location = cms_preview_path(path_params)
      json = { location: location }
      render json: json, status: :ok, content_type: json_content_type
    else
      render json: @item.errors.full_messages, status: :unprocessable_entity
    end
  end

  def move_up_with_overwrite
    @item.column_values.move_up(@cur_column_value.id)
    render_move @item.save
  end

  def move_up_as_branch
    if @item.branches.present?
      @item.errors.add :base, :branch_is_already_existed
      render_save_as_branch false
      return
    end

    @item.cur_site = @cur_site
    @item.cur_node = @item.parent if @item.parent
    @item.cur_user = @cur_user
    branch = @item.new_clone
    branch.master = @item

    id = params[:id].to_s
    @cur_column_value = branch.column_values.to_a.find { |item| item.origin_id.to_s == id }
    @cur_column = @cur_column_value.column

    branch.column_values.move_up(@cur_column_value.id)
    render_move_as_branch branch.save, branch
  end

  def move_down_with_overwrite
    @item.column_values.move_down(@cur_column_value.id)
    render_move @item.save
  end

  def move_down_as_branch
    if @item.branches.present?
      @item.errors.add :base, :branch_is_already_existed
      render_save_as_branch false
      return
    end

    @item.cur_site = @cur_site
    @item.cur_node = @item.parent if @item.parent
    @item.cur_user = @cur_user
    branch = @item.new_clone
    branch.master = @item

    id = params[:id].to_s
    @cur_column_value = branch.column_values.to_a.find { |item| item.origin_id.to_s == id }
    @cur_column = @cur_column_value.column

    branch.column_values.move_down(@cur_column_value.id)
    render_move_as_branch branch.save, branch
  end

  def move_at_with_overwrite
    @item.column_values.move_at(@cur_column_value.id, Integer(params[:order]))
    render_move @item.save
  end

  def move_at_as_branch
    if @item.branches.present?
      @item.errors.add :base, :branch_is_already_existed
      render_save_as_branch false
      return
    end

    order = Integer(params[:order])

    @item.cur_site = @cur_site
    @item.cur_node = @item.parent if @item.parent
    @item.cur_user = @cur_user
    branch = @item.new_clone
    branch.master = @item

    id = params[:id].to_s
    @cur_column_value = branch.column_values.to_a.find { |item| item.origin_id.to_s == id }
    @cur_column = @cur_column_value.column

    branch.column_values.move_at(@cur_column_value.id, order)
    render_move_as_branch branch.save, branch
  end

  public

  def new
    raise "403" if !@item.allowed?(:edit, @cur_user, site: @cur_site)

    if @item.locked? && !@item.lock_owned?
      render json: [ t("errors.messages.locked", user: @item.lock_owner.long_name) ], status: :locked
      return
    end

    @preview = true
    render action: :new
  end

  def create
    @item.attributes = fix_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" if !@item.allowed?(:edit, @cur_user, site: @cur_site)

    @preview = true

    if creates_branch?
      create_as_branch
    else
      create_with_overwrite
    end
  end

  def edit
    raise "403" if !@item.allowed?(:edit, @cur_user, site: @cur_site)

    if @item.locked? && !@item.lock_owned?
      render json: [ t("errors.messages.locked", user: @item.lock_owner.long_name) ], status: :locked
      return
    end

    @preview = true
    render action: :edit
  end

  def update
    safe_params = params.require(:item).permit(@model.permit_params)
    column_value_param = safe_params[:column_values].first
    @cur_column_value.attributes = column_value_param[:in_wrap].merge(column_value_param.slice(:alignment))
    @item.attributes = fix_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    if creates_branch?
      save_as_branch
    else
      save_with_overwrite
    end
  end

  def destroy
    @item.attributes = fix_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    if @item.locked? && !@item.lock_owned?
      render json: [ t("errors.messages.locked", user: @item.lock_owner.long_name) ], status: :locked
      return
    end

    if creates_branch?
      destroy_as_branch
    else
      destroy_with_overwrite
    end
  end

  def move_up
    @item.attributes = fix_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    if @item.locked? && !@item.lock_owned?
      render json: [ t("errors.messages.locked", user: @item.lock_owner.long_name) ], status: :locked
      return
    end

    if creates_branch?
      move_up_as_branch
    else
      move_up_with_overwrite
    end
  end

  def move_down
    @item.attributes = fix_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    if @item.locked? && !@item.lock_owned?
      render json: [ t("errors.messages.locked", user: @item.lock_owner.long_name) ], status: :locked
      return
    end

    if creates_branch?
      move_down_as_branch
    else
      move_down_with_overwrite
    end
  end

  def move_at
    @item.attributes = fix_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    if @item.locked? && !@item.lock_owned?
      render json: [ t("errors.messages.locked", user: @item.lock_owner.long_name) ], status: :locked
      return
    end

    if creates_branch?
      move_at_as_branch
    else
      move_at_with_overwrite
    end
  end

  def link_check
    if params[:id].present?
      set_column_and_value
      safe_params = params.require(:item).permit(@model.permit_params)
      column_value_param = safe_params[:column_values].first
      @cur_column_value.attributes = column_value_param[:in_wrap].merge(column_value_param.slice(:alignment))
    else
      new_column_value
    end

    @cur_column_value.link_check_user = @cur_user
    @cur_column_value.valid?(%i[link])
    render json: @cur_column_value.link_errors.to_json, content_type: json_content_type
  end

  def form_check
    if params[:id].present?
      set_column_and_value
      safe_params = params.require(:item).permit(@model.permit_params)
      column_value_param = safe_params[:column_values].first
      @cur_column_value.attributes = column_value_param[:in_wrap].merge(column_value_param.slice(:alignment))
    else
      new_column_value
    end

    @cur_column_value.valid?(%i[update])
    if creates_branch? && @item.branches.present?
      @cur_column_value.errors.add(:base, :branch_is_already_existed)
    end
    render json: @cur_column_value.errors.full_messages.to_json, content_type: json_content_type
  end
end
