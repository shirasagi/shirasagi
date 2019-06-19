class Gws::Memo::Apis::FoldersController < ApplicationController
  include Gws::ApiFilter

  model Gws::Memo::Folder

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
      case params[:mode]
      when 'manageable'
        @model.site(@cur_site).
          user(@cur_user).
          search(@s)
      when 'all'
        @folders = Gws::Memo::Folder.static_items(@cur_user, @cur_site) +
          Gws::Memo::Folder.user(@cur_user).site(@cur_site).tree_sort.map.to_a
        @folders.each { |folder| folder.site = @cur_site }
        @folders
      else
        @model.none
      end
    end
  end

  public

  def index
    @multi = params[:single].blank?
    @items = @items.tree_sort if @items.respond_to?(:tree_sort)

    respond_to do |format|
      format.html { render }
      format.json { render_json(@items) }
    end
  end

  def render_json(items)
    resp = @items.map do |item|
      {
        name: item.name,
        basename: item.current_name,
        original_name: item.folder_path,
        depth: item.depth,
        unseen: item.unseens.count
      }
    end
    render json: resp.to_json
  end
end
