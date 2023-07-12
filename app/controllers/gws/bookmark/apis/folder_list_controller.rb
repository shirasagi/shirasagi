class Gws::Bookmark::Apis::FolderListController < ApplicationController
  include Gws::ApiFilter
  include Gws::Bookmark::BaseFilter

  model Gws::Bookmark::Folder

  private

  def set_items
    if @folder && params[:only_children]
      @items = @folder.children.tree_sort
    else
      @items = @model.site(@cur_site).user(@cur_user).tree_sort
    end
  end

  public

  def index
    set_items
    render
  end
end
