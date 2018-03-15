class Gws::Share::Apis::FoldersController < ApplicationController
  include Gws::BaseFilter

  model Gws::Share::Folder

  def index
    @limit = 100
    @type = params[:type].presence || 'gws/share/files'
    @item = @model.find(params[:id]) if params[:id].present?

    if params[:only_children]
      items = child_items if @item
    else
      items = root_items
      items += @item.parents.entries + [@item] if @item
      items += tree_items + child_items if @item
    end

    render json: { items: multi_tier_items_hash(items) }.to_json
  end

  private

  def root_items
    if @type == 'gws/share/files'
      @model.site(@cur_site).where(depth: 1).readable(@cur_user, site: @cur_site).limit(@limit)
    elsif @type == 'gws/share/management/files'
      @model.site(@cur_site).where(depth: 1).allow(:read, @cur_user, site: @cur_site).limit(@limit)
    end
  end

  def tree_items
    if @type == 'gws/share/files'
      @item.parents.map do |item|
        next unless item.allowed?(:read, @cur_user, site: @cur_site)
        item.children.readable(@cur_user, site: @cur_site).limit(@limit)
      end.flatten
    elsif @type == 'gws/share/management/files'
      @item.parents.map do |item|
        next unless item.allowed?(:read, @cur_user, site: @cur_site)
        item.children.allow(:read, @cur_user, site: @cur_site).limit(@limit)
      end.flatten
    end
  end

  def child_items
    if @type == 'gws/share/files'
      @item.children.readable(@cur_user, site: @cur_site).limit(@limit)
    elsif @type == 'gws/share/management/files'
      @item.children.allow(:read, @cur_user, site: @cur_site).limit(@limit)
    end
  end

  def multi_tier_items_hash(items)
    return items_hash(items) if @item.blank?
    sorted_items = items_hash(items.select { |item| item.depth == 1 })
    items.map(&:depth).uniq.sort.drop(1).each do |depth|
      cur_items = items.select { |item| item.depth == depth }
      filename = cur_items.first.parents.order_by(depth: -1).first.name
      return sorted_items if filename.blank?
      sorted_items.each_with_index do |sorted_item, index|
        next if sorted_items[index][:filename] != filename
        sorted_items[index] = [sorted_item, items_hash(cur_items)]
        break sorted_items.flatten!
      end
    end
    sorted_items
  end

  def items_hash(items)
    items = items.compact.uniq.sort{ |a, b| (a.order <=> b.order).nonzero? || (a.name <=> b.name) }
    items = items.map do |item|
      {
        name: item.trailing_name,
        filename: item.name,
        order: item.depth == 1 ? item.order : item.parents.where(depth: 1).first.order,
        depth: item.depth,
        url: item_url(item),
        tree_url: gws_share_apis_folders_path(id: item.id, type: @type),
        is_current: (@item.present? && item.id == @item.id),
        is_parent: (@item.present? && @item.name.start_with?("#{item.name}\/"))
      }
    end
    items.uniq.sort_by { |item| item[:order] }
  end

  def item_url(item)
    return gws_share_folder_files_path(folder: item.id) if @type == 'gws/share/files'
    return gws_share_management_folder_files_path(folder: item.id) if @type == 'gws/share/management/files'
    return gws_share_folder_path(id: item.id) if @type == 'gws/share/folders'
  end
end
