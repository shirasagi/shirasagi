class Cms::Node::MaxFileSizesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  navi_view "cms/node/main/navi"
  model Cms::MaxFileSize

  private

  def fix_params
    { cur_site: @cur_site, cur_node: @cur_node }
  end

  def set_items
    if @cur_node.allowed?(:read, @cur_user, site: @cur_site)
      @items = @model.site(@cur_site).node(@cur_node)
    else
      @items = @model.none
    end
  end

  def set_deletable
    return @deletable if instance_variable_defined?(:@deletable)
    @deletable = @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def destroy_items
    raise "400" if @selected_items.blank?
    raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)

    entries = @selected_items.entries
    @items = []

    entries.each do |item|
      item.cur_user = @cur_user if item.respond_to?(:cur_user)
      next if item.destroy
      @items << item
    end
    entries.size != @items.size
  end

  public

  def index
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
    set_items
    @items = @items.search(params[:s]).page(params[:page]).per(50)
    render
  end

  def show
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def new
    raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
    @item = @model.new pre_params.merge(fix_params)
  end

  def create
    raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
    @item = @model.new get_params
    render_create @item.save
  end

  def edit
    raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
    if @item.is_a?(Cms::Addon::EditLock)
      unless @item.acquire_lock
        redirect_to action: :lock
        return
      end
    end
    render
  end

  def update
    raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    render_update @item.update
  end

  def delete
    raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
    render
  end

  def destroy
    raise "403" unless @cur_node.allowed?(:edit, @cur_user, site: @cur_site)
    @item.cur_user = @cur_user if @item.respond_to?(:cur_user)
    render_destroy @item.destroy
  end
end
