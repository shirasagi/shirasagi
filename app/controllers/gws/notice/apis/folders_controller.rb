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
    @items ||= begin
      if params[:mode] == 'manageable'
        items = @model.for_post_manager(@cur_site, @cur_user)
      elsif params[:mode] == 'editable'
        items = @model.for_post_editor(@cur_site, @cur_user)
      elsif params[:mode] == 'readable'
        items = @model.for_post_reader(@cur_site, @cur_user)
      else
        items = @model.none
      end

      items.nin(id: @excepts).search(@s)
    end
  end

  public

  def index
    @multi = params[:single].blank?
    @items = @items.tree_sort
  end
end
