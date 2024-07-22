module Cms::NodeFilter
  extend ActiveSupport::Concern
  include Cms::CrudFilter

  included do
    prepend_view_path "app/views/cms/nodes"
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :move, :move_confirm]
    before_action :change_item_class, if: -> { @item.present? }
    before_action :set_tree_navi, only: [:index]
  end

  private

  def set_item
    super
    if @cur_node
      raise "500" if @item.id == @cur_node.id && @item.collection_name.to_s == "cms_nodes"
    end
  end

  def change_item_class
    @item.route = params[:route] if params[:route]
    @item = @item.becomes_with_route(@item.route) rescue @item
    @model = @item.class
  end

  def redirect_url
    diff = @item.route.pluralize != params[:controller]
    diff ? node_node_path(cid: @cur_node, id: @item.id) : { action: :show, id: @item.id }
  end

  public

  def index
    @items = @model.site(@cur_site).node(@cur_node).
      allow(:read, @cur_user).
      search(params[:s]).
      order_by(filename: 1).
      page(params[:page]).per(50)
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
    change_item_class

    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
  end

  def create
    @item = @model.new get_params
    change_item_class
    @item.attributes = get_params

    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    render_create @item.save, location: redirect_url
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    render_update @item.update, location: redirect_url
  end

  def move
    @filename   = params[:filename]
    @source     = params[:source]
    @link_check = params[:link_check]
    destination = params[:destination]
    confirm     = params[:confirm]
    if request.get? || request.head?
      @filename = @item.filename
    elsif confirm
      @source = "/#{@item.filename}/"
      @item.validate_destination_filename(destination)
      @item.filename = destination
      @link_check = @item.errors.empty?
    else
      @source = "/#{@item.filename}/"
      raise "403" unless @item.allowed?(:move, @cur_user, site: @cur_site, node: @cur_node)

      if (params[:parent_node_id])
        parent_node = Cms::Node.where(site_id: @cur_site.id, id: params[:parent_node_id]).first
        @item.update(cur_node: parent_node) if parent_node
      end
      
      if (@item.reload.cur_node.present?) 
        destination = "#{@item.cur_node.filename}/#{destination}" unless destination.include?(@item.cur_node.filename)
      end

      if @item.move(destination)
        location = { action: :show }
        render_update true, location: location, render: { template: "show" }, notice: t('ss.notice.moved')
      else
        location = { action: :move } 
        render_update false, location: location, render: { template: "move" }, notice: t('ss.notice.moved')
      end
    end
  end

  def command
    set_item rescue nil
    if @item.blank?
      head :no_content
      return
    end

    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    raise "403" unless Cms::Command.allowed?(:use, @cur_user, site: @cur_site, node: @cur_node)

    @commands = Cms::Command.site(@cur_site).allow(:use, @cur_user, site: @cur_site).order_by(order: 1, id: 1)
    @target = 'folder'
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
end
