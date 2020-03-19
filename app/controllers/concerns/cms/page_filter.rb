module Cms::PageFilter
  extend ActiveSupport::Concern
  include Cms::CrudFilter

  included do
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :move, :copy, :contains_urls]
    before_action :set_contains_urls_items, only: [:contains_urls, :edit, :delete]
  end

  private

  def set_item
    super
    return unless @cur_node
    return if (@item.filename =~ /^#{::Regexp.escape(@cur_node.filename)}\//) && (@item.depth == @cur_node.depth + 1)
    raise "404"
  end

  def pre_params
    params = {}

    if @cur_node
      n = @cur_node.class == Cms::Node ? @cur_node.becomes_with_route : @cur_node

      layout_id = n.page_layout_id || n.layout_id
      params[:layout_id] = layout_id if layout_id.present?

      if n.respond_to?(:st_forms) && n.st_form_ids.include?(n.st_form_default_id)
        default_form = n.st_form_default
        if default_form.present? && default_form.allowed?(:read, @cur_user, site: @cur_site)
          params[:form_id] = default_form.id
        end
      end
    end

    params
  end

  def set_items
    @items = @model.site(@cur_site).node(@cur_node)
      .allow(:read, @cur_user)
      .order_by(updated: -1)
  end

  def set_contains_urls_items
    @contains_urls = []
    return unless @item.class.include?(Cms::Model::Page)

    cond = []
    if @item.respond_to?(:url) && @item.respond_to?(:full_url)
      cond << { contains_urls: { '$in' => [ @item.url, @item.full_url ] } }
    end

    if @item.respond_to?(:files) && @item.files.present?
      cond << { contains_urls: { '$in' => @item.files.map(&:url) } }
    end

    if @item.respond_to?(:related_page_ids)
      cond << { related_page_ids: { '$in' => [ @item.id ] } }
    end

    if cond.present?
      @contains_urls = Cms::Page.site(@cur_site).where(:id.ne => @item.id).or(cond).
        page(params[:page]).per(50)
    end
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
    # if params.dig(:item, :column_values).present? && @item.form.present?
    #   new_column_values = @item.build_column_values(params.dig(:item, :column_values))
    #   @item.update_column_values(new_column_values)
    # end
    if @item.state == "public"
      raise "403" unless @item.allowed?(:release, @cur_user, site: @cur_site, node: @cur_node)
      @item.state = "ready" if @item.try(:release_date).present?
    end

    result = @item.update
    location = nil
    if result && @item.try(:branch?) && @item.state == "public"
      location = { action: :index }
      @item.file_ids = nil if @item.respond_to?(:file_ids)
      @item.skip_history_trash = true if @item.respond_to?(:skip_history_trash)
      @item.destroy
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

  def move
    @filename   = params[:filename]
    @source     = params[:source]
    @link_check = params[:link_check]
    destination = params[:destination]
    confirm     = params[:confirm]

    if request.get?
      @filename = @item.filename
    elsif confirm
      @source = "/#{@item.filename}"
      @item.validate_destination_filename(destination)
      @item.filename = destination
      @link_check = @item.errors.empty?
    else
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

      render_update @item.move(destination), location: location, render: { file: :move }
    end
  end

  def copy
    if request.get?
      prefix = I18n.t("workflow.cloned_name_prefix")
      @item.name = "[#{prefix}] #{@item.name}" unless @item.cloned_name?
      return
    end

    @item.attributes = get_params
    @copy = @item.new_clone
    render_update @copy.save, location: { action: :index }, render: { file: :copy }
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

    return if request.get?

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

    render_update true, location: { action: :index }, render: { file: :index }
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

    render_update true, location: { action: :index }, render: { file: :index }
  end
end
