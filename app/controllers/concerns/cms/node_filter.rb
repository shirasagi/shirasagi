module Cms::NodeFilter
  extend ActiveSupport::Concern
  include Cms::CrudFilter

  included do
    prepend_view_path "app/views/cms/nodes"
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :move]
    before_action :change_item_class, if: -> { @item.present? }
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
    @item  = @item.becomes_with_route rescue @item
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

    if request.get?
      @filename = @item.filename
    elsif confirm
      @source = "/#{@item.filename}/"
      @item.validate_destination_filename(destination)
      @item.filename = destination
      @link_check = @item.errors.empty?
    else
      @source = "/#{@item.filename}/"
      raise "403" unless @item.allowed?(:move, @cur_user, site: @cur_site, node: @cur_node)

      location = { action: :move, source: @source, link_check: true }
      render_update @item.move(destination), location: location, render: { file: :move }
    end
  end
end
