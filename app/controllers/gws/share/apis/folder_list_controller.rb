class Gws::Share::Apis::FolderListController < ApplicationController
  include Gws::BaseFilter

  model Gws::Share::Folder

  def index
    @limit = SS.config.gws.share["folder_navi_limit"]
    @type = params[:type].presence || 'gws/share/files'
    @item = @model.find(params[:id]) if params[:id].present?

    if params[:only_children]
      items = []
      items = child_items if @item
    else
      items = root_items.entries
      if @item
        items = append_items(items, @item.parents.entries + [@item])
        items = append_tree_items(items)
        items = append_items(items, child_items.entries, @item)
      end
    end

    render json: { items: items_hash(items) }.to_json
  end

  private

  def append_items(items, add_items, pos_item = nil)
    add_items = add_items.to_a
    return items if add_items.blank?
    pos_item ||= add_items.first

    items.each_with_index do |item, idx|
      if item == pos_item
        items.insert(idx + 1, *add_items)
        break
      end
    end
    items
  end

  def append_tree_items(items)
    case @type
    when 'gws/share/files'
      @item.parents.each do |item|
        next unless item.allowed?(:read, @cur_user, site: @cur_site)
        children = item.children.readable(@cur_user, site: @cur_site)
        children = children.limit(@limit) if @limit
        items = append_items(items, children, item)
      end
    when 'gws/share/management/files'
      @item.parents.each do |item|
        next unless item.allowed?(:read, @cur_user, site: @cur_site)
        children = item.children.allow(:read, @cur_user, site: @cur_site)
        children = children.limit(@limit) if @limit
        items = append_items(items, children, item)
      end
    end
    items
  end

  def root_items
    case @type
    when 'gws/share/files'
      items = @model.site(@cur_site).where(depth: 1).readable(@cur_user, site: @cur_site)
      items = items.limit(@limit) if @limit
      items
    when 'gws/share/management/files'
      items = @model.site(@cur_site).where(depth: 1).allow(:read, @cur_user, site: @cur_site)
      items = items.limit(@limit) if @limit
      items
    end
  end

  def child_items
    case @type
    when 'gws/share/files'
      items = @item.children.readable(@cur_user, site: @cur_site)
      items = items.limit(@limit) if @limit
      items
    when 'gws/share/management/files'
      items = @item.children.allow(:read, @cur_user, site: @cur_site)
      items = items.limit(@limit) if @limit
      items
    end
  end

  def items_hash(items)
    items = items.compact.map do |item|
      {
        name: item.trailing_name,
        filename: item.name,
        order: item.depth == 1 ? item.order : item.parents.where(depth: 1).first.order,
        depth: item.depth,
        url: item_url(item),
        tree_url: gws_share_apis_folder_list_path(id: item.id, type: @type, category: params[:category]),
        is_current: (@item.present? && item.id == @item.id),
        is_parent: (@item.present? && @item.name.start_with?("#{item.name}/"))
      }
    end
    items.uniq
  end

  def item_url(item)
    case @type
    when 'gws/share/files'
      gws_share_folder_files_path(folder: item.id, category: params[:category])
    when 'gws/share/management/files'
      gws_share_management_folder_files_path(folder: item.id, category: params[:category])
    when 'gws/share/folders'
      gws_share_folder_path(id: item.id)
    end
  end
end
