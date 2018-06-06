class Gws::Notice::Apis::FoldersController < ApplicationController
  include Gws::ApiFilter

  model Gws::Notice::Folder

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
    @items ||= @model.site(@cur_site).
      nin(id: @excepts).
      allow(:read, @cur_user, site: @cur_site).
      search(@s)
  end

  public

  def index
    @multi = params[:single].blank?
    @items = @items.tree_sort
  end
end
