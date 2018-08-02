module Cms::TrashFilter
  extend ActiveSupport::Concern

  included do
    append_view_path 'app/views/cms/crud/trash'
    menu_view 'cms/crud/trash/menu'
  end

  def soft_delete
    set_item unless @item
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    if request.get?
      render
      return
    end

    @item.deleted = Time.zone.now
    render_destroy @item.save
  end

  def undo_delete
    set_item
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    if request.get?
      render
      return
    end

    @item.deleted = nil

    render_opts = {}
    render_opts[:location] = { action: :index }
    render_opts[:render] = { file: :undo_delete }
    render_opts[:notice] = t('ss.notice.restored')

    render_update @item.save, render_opts
  end

  def soft_delete_all
    set_selected_items unless @items

    entries = @items.entries
    @items = []

    entries.each do |item|
      item.try(:cur_site=, @cur_site)
      item.try(:cur_user=, @cur_user)
      if item.allowed?(:delete, @cur_user, site: @cur_site)
        item.deleted = Time.zone.now
        next if item.save
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  private

  def set_item
    @item = @model.unscoped.site(@cur_site).find(params[:id])
    @item.attributes = fix_params
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end
end
