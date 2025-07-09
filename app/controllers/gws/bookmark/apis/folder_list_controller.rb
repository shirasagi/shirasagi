class Gws::Bookmark::Apis::FolderListController < ApplicationController
  include Gws::ApiFilter
  include Gws::Bookmark::BaseFilter

  model Gws::Bookmark::Folder

  private

  def set_items
    set_child_count

    if @folder && params[:only_children]
      @items = @folder.children.tree_sort
    else
      @items = @model.site(@cur_site).user(@cur_user).tree_sort
    end
  end

  def set_child_count
    @child_count = Hash.new(0)
    @model.site(@cur_site).user(@cur_user).pluck(:name, :depth).each do |name, depth|
      next if depth == 1
      parts = name.split("/")
      child = parts.pop
      parent = parts.join("/")
      @child_count[parent] ||= 0
      @child_count[parent] += 1
    end
  end

  public

  def index
    set_items
    render
  end
end
