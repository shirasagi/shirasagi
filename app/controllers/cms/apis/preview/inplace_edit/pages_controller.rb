class Cms::Apis::Preview::InplaceEdit::PagesController < ApplicationController
  include Cms::ApiFilter
  include Cms::InplaceEditFilter

  model Cms::Page

  layout "ss/ajax_in_iframe"

  before_action :set_cur_node
  before_action :set_inplace_mode

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_item
    super
    return @item if @item.blank? || @item.class != Cms::Page

    @model = @item.class
  end

  def set_cur_node
    @cur_node ||= begin
      parent = @item.parent
      parent || nil
    end
  end

  def set_inplace_mode
    @inplace_mode = true
  end

  def save_with_overwrite
    result = @item.save

    if !result
      render template: "edit", status: :unprocessable_entity
      return
    end

    flash["cms.preview.notice"] = I18n.t("ss.notice.saved")
    render json: { reload: true }, status: :ok, content_type: json_content_type
  end

  def save_as_branch
    if @item.branches.present?
      @item.errors.add :base, :branch_is_already_existed
      render_save_as_branch false
      return
    end

    copy = nil
    result = nil
    task = SS::Task.find_or_create_for_model(@item, site: @cur_site)
    rejected = -> { @item.errors.add :base, :other_task_is_running }
    task.run_with(rejected: rejected) do
      task.log "# #{I18n.t("workflow.branch_page")} #{I18n.t("ss.buttons.new")}"

      @item.cur_site = @cur_site
      @item.cur_node = @item.parent if @item.parent
      @item.cur_user = @cur_user
      copy = @item.new_clone
      copy.master = @item
      result = copy.save
    end

    if result
      path_params = { path: copy.filename, anchor: "inplace" }
      path_params[:preview_date] = params[:preview_date].to_s if params[:preview_date].present?
      location = cms_preview_path(path_params)
    elsif copy && copy.errors.present?
      SS::Model.copy_errors(copy, @item)
    end

    render_save_as_branch result, location
  end

  def render_save_as_branch(result, location = nil)
    if result && location
      flash["cms.preview.notice"] = I18n.t("workflow.notice.created_branch_page")
      render json: { location: location }, status: :ok, content_type: json_content_type
    else
      render template: "edit", status: :unprocessable_entity
    end
  end

  public

  def edit
    raise "403" if !@item.allowed?(:edit, @cur_user, site: @cur_site)
    super
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" if !@item.allowed?(:edit, @cur_user, site: @cur_site)

    if creates_branch?
      save_as_branch
    else
      save_with_overwrite
    end
  end
end
