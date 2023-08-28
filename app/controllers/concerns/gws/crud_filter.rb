module Gws::CrudFilter
  extend ActiveSupport::Concern
  include SS::CrudFilter

  included do
    menu_view "gws/crud/menu"
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :soft_delete]
    before_action :set_selected_items, only: [:destroy_all, :soft_delete_all]
  end

  private

  def append_view_paths
    append_view_path "app/views/gws/crud"
    append_view_path "app/views/ss/crud"
  end

  def set_item
    if @model.respond_to?(:site)
      @item = @model.site(@cur_site).find(params[:id])
    else
      @item = @model.find(params[:id])
    end
    @item.attributes = fix_params
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def set_items
    if @model.respond_to?(:site)
      @items = @model.site(@cur_site).allow(:read, @cur_user, site: @cur_site)
    else
      @items = @model.allow(:read, @cur_user, site: @cur_site)
    end
  end

  def set_selected_items
    ids = params[:ids]
    raise "400" unless ids
    ids = ids.split(",") if ids.is_a?(String)
    if @model.respond_to?(:site)
      @selected_items = @items = @model.in(id: ids).site(@cur_site)
    else
      @selected_items = @items = @model.in(id: ids)
    end
    raise "400" unless @items.present?
  end

  public

  def index
    # raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def show
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def create
    @item = @model.new get_params
    return render_create(false) unless @item.allowed?(:edit, @cur_user, site: @cur_site, strict: true)
    render_create @item.save
  end

  def edit
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    if @item.is_a?(Cms::Addon::EditLock) && !@item.acquire_lock
      redirect_to action: :lock
      return
    end
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    return render_update(false) unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update
  end

  def delete
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.destroy
  end

  def soft_delete
    set_item unless @item
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    if request.get? || request.head?
      render
      return
    end

    @item.record_timestamps = false
    @item.deleted = Time.zone.now
    render_destroy @item.save
  end

  def undo_delete
    set_item
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    if request.get? || request.head?
      render
      return
    end

    @item.record_timestamps = false
    @item.deleted = nil

    render_opts = {}
    render_opts[:location] = { action: :index }
    render_opts[:render] = { template: "undo_delete" }
    render_opts[:notice] = t('ss.notice.restored')

    render_update @item.save, render_opts
  end

  def destroy_all
    raise "400" if @selected_items.blank?

    entries = @selected_items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site)
        next if item.destroy
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_confirmed_all(entries.size != @items.size)
  end

  def disable_all
    raise "400" if @selected_items.blank?

    entries = @selected_items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site)
        item.attributes = fix_params
        if item.is_a?(Gws::User) && item.deletion_unlocked? && item.disabled?
          item.destroy
          next
        end
        next if item.disable
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_confirmed_all(entries.size != @items.size)
  end

  def soft_delete_all
    set_selected_items unless @selected_items

    raise "400" if @selected_items.blank?

    entries = @selected_items.entries
    @items = []

    entries.each do |item|
      item.try(:cur_site=, @cur_site)
      item.try(:cur_user=, @cur_user)
      if item.allowed?(:delete, @cur_user, site: @cur_site)
        item.record_timestamps = false
        item.deleted = Time.zone.now
        next if item.save
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_confirmed_all(entries.size != @items.size)
  end
end
