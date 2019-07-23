class History::Cms::TrashesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model History::Trash

  navi_view "cms/main/navi"

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    @ref_coll_options = [Cms::Node, Cms::Page, Cms::Part, Cms::Layout].collect do |model|
      [model.model_name.human, model.collection_name]
    end
    @ref_coll_options.unshift([I18n.t('ss.all'), 'all'])
    set_items
    @s = OpenStruct.new params[:s]
    @s[:ref_coll] ||= 'all'
    @items = @items.search(@s)
      .order_by(created: -1)
      .page(params[:page])
      .per(50)
  end

  def undo_delete
    set_item
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    if request.get?
      render
      return
    end

    render_opts = {}
    render_opts[:location] = { action: :index }
    render_opts[:render] = { file: :undo_delete }
    render_opts[:notice] = t('ss.notice.restored')

    result = @item.restore!(get_params)
    @item.children.restore!(get_params) if params.dig(:item, :children) == 'restore' && @item.ref_coll == 'cms_nodes' && result
    render_update result, render_opts
  end

  def undo_delete_all
    set_selected_items
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
        next if item.restore!
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size, notice: t('ss.notice.restored'))
  end
end
