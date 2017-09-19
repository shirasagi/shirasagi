module Sys::CrudFilter
  extend ActiveSupport::Concern
  include SS::CrudFilter

  included do
    menu_view "ss/crud/menu"
  end

  def index
    @items = @model.allow(:read, @cur_user).
      order_by(_id: -1).
      page(params[:page]).per(100)
  end

  def show
    raise "403" unless @item.allowed?(:read, @cur_user)
    render
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
    raise "403" unless @item.allowed?(:edit, @cur_user)
  end

  def create
    @item = @model.new get_params
    raise "403" unless @item.allowed?(:edit, @cur_user)
    render_create @item.save
  end

  def edit
    raise "403" unless @item.allowed?(:edit, @cur_user)
    render
  end

  def update
    @item.attributes = get_params
    raise "403" unless @item.allowed?(:edit, @cur_user)
    render_update @item.update
  end

  def delete
    raise "403" unless @item.allowed?(:delete, @cur_user)
    render
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user)
    render_destroy @item.destroy
  end

  def destroy_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site)
        next if item.destroy
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def disable_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site)
        next if item.disable
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end
end
