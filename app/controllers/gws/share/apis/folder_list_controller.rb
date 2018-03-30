class Gws::Share::Apis::FolderListController < ApplicationController
  include Gws::BaseFilter

  model Gws::Share::Folder

  def index
    @limit = 100
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
    if @type == 'gws/share/files'
      @item.parents.each do |item|
        next unless item.allowed?(:read, @cur_user, site: @cur_site)
        items = append_items(items, item.children.readable(@cur_user, site: @cur_site).limit(@limit).entries, item)
      end
    elsif @type == 'gws/share/management/files'
      @item.parents.each do |item|
        next unless item.allowed?(:read, @cur_user, site: @cur_site)
        items = append_items(items, item.children.allow(:read, @cur_user, site: @cur_site).limit(@limit).entries, item)
      end
    end
    items
  end

  def root_items
    if @type == 'gws/share/files'
      @model.site(@cur_site).where(depth: 1).readable(@cur_user, site: @cur_site).limit(@limit)
    elsif @type == 'gws/share/management/files'
      @model.site(@cur_site).where(depth: 1).allow(:read, @cur_user, site: @cur_site).limit(@limit)
    end
  end

  def child_items
    if @type == 'gws/share/files'
      @item.children.readable(@cur_user, site: @cur_site).limit(@limit)
    elsif @type == 'gws/share/management/files'
      @item.children.allow(:read, @cur_user, site: @cur_site).limit(@limit)
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
        tree_url: gws_share_apis_folder_list_path(id: item.id, type: @type),
        is_current: (@item.present? && item.id == @item.id),
        is_parent: (@item.present? && @item.name.start_with?("#{item.name}\/"))
      }
    end
    items.uniq
  end

  def item_url(item)
    return gws_share_folder_files_path(folder: item.id) if @type == 'gws/share/files'
    return gws_share_management_folder_files_path(folder: item.id) if @type == 'gws/share/management/files'
    return gws_share_folder_path(id: item.id) if @type == 'gws/share/folders'
  end
end
