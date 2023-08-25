module Cms::PageFilter
  extend ActiveSupport::Concern
  include Cms::CrudFilter
  include Cms::MicheckerFilter

  included do
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :move, :copy, :contains_urls]
    before_action :set_contains_urls_items, only: [:contains_urls, :edit, :update, :delete, :destroy]
    before_action :deny_update_with_contains_urls, only: [:update]
    before_action :deny_destroy_with_contains_urls, only: [:destroy]
  end

  private

  def set_item
    super
    return unless @cur_node
    return if (@item.filename =~ /^#{::Regexp.escape(@cur_node.filename)}\//) && (@item.depth == @cur_node.depth + 1)
    raise "404"
  end

  def default_form(node)
    return if !node.respond_to?(:st_forms)
    return if !node.st_form_ids.include?(node.st_form_default_id)
    return if !@model.fields.key?("form_id")

    default_form = node.st_form_default
    return if default_form.blank?
    return if !default_form.allowed?(:read, @cur_user, site: @cur_site)

    default_form
  end

  def pre_params
    params = {}

    if @cur_node
      n = @cur_node

      layout_id = n.page_layout_id || n.layout_id
      params[:layout_id] = layout_id if layout_id.present?

      default_form(n).try do |form|
        params[:form_id] = form.id
      end
    end

    params
  end

  def set_items
    @items = @model.site(@cur_site).node(@cur_node)
      .allow(:read, @cur_user)
      .custom_order(params.dig(:s, :sort) || 'updated_desc')
  end

  def set_contains_urls_items
    @contains_urls = Cms::Page.none if !@item.is_a?(Cms::Model::Page) || @item.try(:branch?) || params[:branch_save].present?
    @contains_urls ||= Cms::Page.all.site(@cur_site).and_linking_pages(@item).page(params[:page]).per(50)
  end

  def deny_update_with_contains_urls
    return if @cur_user.cms_role_permit_any?(@cur_site, %w(edit_cms_ignore_alert))
    return if @contains_urls.try(:and_public).blank?
    return unless @item.public?
    return if params.dig(:item, :state) == 'public'

    raise "403"
  end

  def deny_destroy_with_contains_urls
    return if @cur_user.cms_role_permit_any?(@cur_site, %w(delete_cms_ignore_alert))
    return if @contains_urls.try(:and_public).blank?

    raise "403"
  end

  def draft_save
    raise ArgumentError if %w(ready public).include?(@item.state)

    result = @item.save

    if !result && @item.is_a?(Cms::Addon::EditLock)
      # So, edit lock must be held
      unless @item.acquire_lock
        location = { action: :lock }
      end
    end

    render_update result, location: location
  end

  def publish_save
    raise ArgumentError if !%w(ready public).include?(@item.state)

    @item.state = "ready" if @item.try(:release_date).present?

    result = save_with_task(@item)

    location = nil
    if result && destroy_merged_branch(@item)
      location = { action: :index }
    end

    # If page is failed to update, page is going to show in edit mode with update errors
    if !result && @item.is_a?(Cms::Addon::EditLock)
      # So, edit lock must be held
      unless @item.acquire_lock
        location = { action: :lock }
      end
    end

    render_update result, location: location
  end

  def save_with_task(item)
    return item.save if item.try(:master_id).nil?

    task = SS::Task.find_or_create_for_model(item.master, site: @cur_site)
    rejected = -> { item.errors.add :base, :other_task_is_running }
    task.run_with(rejected: rejected) do
      task.log "# #{I18n.t("workflow.branch_page")} #{I18n.t("ss.buttons.publish_save")}"
      item.save
    end
    item.errors.blank?
  end

  def destroy_merged_branch(item)
    return false if !item.try(:branch?)
    return false if item.state != "public"

    item.file_ids = nil if item.respond_to?(:file_ids)
    item.skip_history_trash = true if item.respond_to?(:skip_history_trash)
    item.destroy
    true
  end

  def save_as_branch
    if @item.branches.present?
      @item.errors.add :base, :branch_is_already_existed
      render_update false
      return
    end

    copy = nil
    result = nil
    SS::Task.find_or_create_for_model(@item, site: @cur_site).tap do |task|
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
    end

    render_opts = {}
    if result
      render_opts[:location] = url_for(action: :show, id: copy)
      render_opts[:notice] = I18n.t("workflow.notice.created_branch_page")
    elsif copy && copy.errors.present?
      @item.errors.messages[:base] += copy.errors.full_messages
    end

    render_update result, render_opts
  end

  def change_items_state
    raise "400" if @selected_items.blank?

    entries = @selected_items.entries
    @items = []

    role_action = :edit
    if @model.include?(Cms::Addon::Release)
      role_action = :release if @change_state == 'public'
      role_action = :close if @change_state == 'closed'
    end

    entries.each do |item|
      if item.allowed?(role_action, @cur_user, site: @cur_site, node: @cur_node)
        item.cur_user = @cur_user if item.respond_to?(:cur_user)
        item.state = @change_state if item.respond_to?(:state)

        if save_with_task(item)
          destroy_merged_branch(item)
          next
        end
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    entries.size != @items.size
  end

  public

  def index
    if @cur_node
      raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      set_items
      @items = @items.search(params[:s]).
        page(params[:page]).per(50)
    end
  end

  def create
    @item = @model.new get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    # if params.dig(:item, :column_values).present? && @item.form.present?
    #   new_column_values = @item.build_column_values(params.dig(:item, :column_values))
    #   @item.update_column_values(new_column_values)
    # end
    if @item.state == "public"
      raise "403" unless @item.allowed?(:release, @cur_user, site: @cur_site, node: @cur_node)
      @item.state = "ready" if @item.try(:release_date).present?
    end
    render_create @item.save
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    if params[:branch_save] == I18n.t("cms.buttons.save_as_branch")
      # 差し替え保存
      save_as_branch
      return
    end

    if %w(ready public).include?(@item.state)
      # 公開保存
      raise "403" unless @item.allowed?(:release, @cur_user, site: @cur_site, node: @cur_node)

      publish_save
      return
    end

    if %w(ready public).include?(@item.state_was)
      if @item.is_a?(Workflow::Addon::Branch) && @item.branch?
        # 差し替えページは公開権限がなくても取り下げ保存が可能
      elsif !@item.allowed?(:close, @cur_user, site: @cur_site, node: @cur_node)
        # 公開ページだった場合、非公開とするには非公開権限が必要
        raise "403"
      end
    end

    draft_save
  end

  def move
    @filename   = params[:filename]
    @source     = params[:source]
    @link_check = params[:link_check]
    destination = params[:destination]
    confirm     = params[:confirm]

    if request.get? || request.head?
      @filename = @item.filename
      return
    end
    raise "400" if @item.respond_to?(:branch?) && @item.branch?

    if confirm
      @source = "/#{@item.filename}"
      @item.validate_destination_filename(destination)
      @item.filename = destination
      @link_check = @item.errors.empty?
      return
    end

    @source = "/#{@item.filename}"
    raise "403" unless @item.allowed?(:move, @cur_user, site: @cur_site, node: @cur_node)

    node = Cms::Node.site(@cur_site).filename(::File.dirname(destination)).first

    if node.blank?
      location = move_cms_page_path id: @item.id, source: @source, link_check: true
    elsif @item.route == "cms/page"
      location = move_node_page_path cid: node.id, id: @item.id, source: @source, link_check: true
    else
      location = { cid: node.id, action: :move, source: @source, link_check: true }
    end

    task = SS::Task.find_or_create_for_model(@item, site: @cur_site)

    rejected = -> do
      @item.errors.add :base, :other_task_is_running
      render
    end

    task.run_with(rejected: rejected) do
      task.log "# #{I18n.t("ss.buttons.move")}"
      render_update @item.move(destination), location: location, render: { template: "move" }, notice: t('ss.notice.moved')
    end
  end

  def copy
    if request.get? || request.head?
      prefix = I18n.t("workflow.cloned_name_prefix")
      @item.name = "[#{prefix}] #{@item.name}" unless @item.cloned_name?
      return
    end

    task = SS::Task.find_or_create_for_model(@item, site: @cur_site)

    rejected = -> do
      @item.errors.add :base, :other_task_is_running
      render
    end

    task.run_with(rejected: rejected) do
      task.log "# #{I18n.t("ss.links.copy")}"

      @item.attributes = get_params
      @copy = @item.new_clone
      render_update @copy.save, location: { action: :index }, render: { template: "copy" }
    end
  end

  def command
    set_item rescue nil
    if @item.blank?
      head :no_content
      return
    end

    raise "403" unless @item.allowed?(:release, @cur_user, site: @cur_site, node: @cur_node)
    raise "403" unless Cms::Command.allowed?(:use, @cur_user, site: @cur_site, node: @cur_node)

    @commands = Cms::Command.site(@cur_site).allow(:use, @cur_user, site: @cur_site).order_by(order: 1, id: 1)
    @target = 'page'
    @target_path = @item.path

    return if request.get? || request.head?

    @commands.each do |command|
      command.run(@target, @target_path)
    end
    respond_to do |format|
      format.html { redirect_to({ action: :command }, { notice: t('ss.notice.run') }) }
      format.json { head :no_content }
    end
  end

  def contains_urls
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    render
  end

  def set_tag_all
    if @cur_node
      safe_params = params.permit(:tag, ids: [])
      ids = safe_params[:ids].presence || []
      tag = safe_params[:tag].presence
      if tag
        @model.site(@cur_site).node(@cur_node).in(_id: ids).allow(:edit, @cur_user).each do |item|
          item.add_to_set(tags: [ tag ])
        end
      end
    end

    render_update true, location: { action: :index }, render: { template: "index" }
  end

  def reset_tag_all
    if @cur_node
      safe_params = params.permit(:tag, ids: [])
      ids = safe_params[:ids].presence || []
      tag = safe_params[:tag].presence
      if tag
        @model.site(@cur_site).node(@cur_node).in(_id: ids).allow(:edit, @cur_user).each do |item|
          item.pull(tags: tag)
        end
      end
    end

    render_update true, location: { action: :index }, render: { template: "index" }
  end
end
