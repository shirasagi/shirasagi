class Gws::Bookmark::Apis::FoldersController < ApplicationController
  include Gws::ApiFilter
  include Gws::Bookmark::BaseFilter

  model Gws::Bookmark::Folder

  before_action :set_search_params
  before_action :set_excepts
  before_action :set_items

  private

  def set_search_params
    @s ||= params[:s]
  end

  def set_excepts
    @excepts ||= Array(params[:except]).flatten.select(&:numeric?).map(&:to_i)
  end

  def set_items
    @items = @folders
  end

  public

  def index
    @multi = params[:single].blank?
    @items = @items.tree_sort
  end
end
