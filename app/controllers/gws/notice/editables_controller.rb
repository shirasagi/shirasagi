class Gws::Notice::EditablesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  before_action :set_folders
  before_action :set_folder
  before_action :set_categories
  before_action :set_category
  before_action :set_search_params
  before_action :set_items
  before_action :set_item, only: [:show, :edit, :update, :soft_delete]

  model Gws::Notice::Post

  navi_view "gws/notice/main/navi"

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/notice/post"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_folders
    @folders ||= Gws::Notice::Folder.site(@cur_site).allow(:read, @cur_user, site: @cur_site)
  end

  def set_folder
    return if params[:folder_id].blank? || params[:folder_id] == '-'
    @folder = @folders.find(params[:folder_id])
  end

  def set_categories
    @categories ||= Gws::Notice::Category.site(@cur_site).readable(@cur_user, site: @cur_site)
  end

  def set_category
    return if params[:category_id].blank? || params[:category_id] == '-'
    @category ||= @categories.find(id: params[:category_id])
    raise '403' unless @category.readable?(@cur_user) || @category.allowed?(:read, @cur_user, site: @cur_site)
  end

  def set_search_params
    @s = params[:s].presence || {}
    @s[:folder_id] = @folder.id if @folder.present?
    @s[:category_id] = @category.id if @category.present?
  end

  def set_items
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      without_deleted.
      search(@s)
  end

  def set_item
    @item ||= begin
      item = @items.find(params[:id])
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  public

  def index
    @categories = @categories.tree_sort
    @items = @items.page(params[:page]).per(50)
  end
end
