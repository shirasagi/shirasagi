class History::Cms::TrashesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model History::Trash

  navi_view "cms/main/navi"

  def undo_delete
    set_item
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    if request.get?
      render
      return
    end

    render_opts = {}
    render_opts[:location] = { action: :index }
    render_opts[:render] = { file: :undo_delete }
    render_opts[:notice] = t('ss.notice.restored')

    render_update @item.restore!, render_opts
  end

  def undo_delete_all
    set_selected_items
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
        next if item.restore!
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size, notice: t('ss.notice.restored'))
  end
end
