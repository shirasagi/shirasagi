class Gws::Notice::ReadablesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  before_action :set_folders
  before_action :set_folder
  before_action :set_categories
  before_action :set_category
  before_action :set_search_params
  before_action :set_items
  before_action :set_item, only: [:show, :toggle_browsed]

  model Gws::Notice::Post

  navi_view "gws/notice/main/navi"

  private

  def set_selected_group
    if params[:group].present? && params[:group] != '-'
      @selected_group = @cur_site.descendants.active.where(id: params[:group]).first
    end

    @selected_group ||= @cur_site
    @selected_group
  end

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/notice/post"), gws_notice_main_path]
    @crumbs << [t('ss.navi.readable'), action: :index, folder_id: '-', category_id: '-']
  end

  def set_folders
    @folders ||= Gws::Notice::Folder.for_post_reader(@cur_site, @cur_user)
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
    @s = OpenStruct.new(params[:s].presence)
    @s[:site] = @cur_site
    @s[:user] = @cur_user
    if @folder.present?
      @s[:folder_ids] = [ @folder.id ]
      @s[:folder_ids] += @folder.folders.for_post_reader(@cur_site, @cur_user).pluck(:id)
    end
    @s[:category_id] = @category.id if @category.present?
    @s[:browsed_state] ||= SS.config.gws.notice['portal_browsed_state'].presence
  end

  def set_items
    @items = @model.site(@cur_site).and_public.
      readable(@cur_user, site: @cur_site).
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

  def show
    render
  end

  def toggle_browsed
    if @item.browsed?(@cur_user)
      @item.unset_browsed!(@cur_user)
    else
      @item.set_browsed!(@cur_user)
    end

    render_update true
  rescue => e
    render_update false
  end
end
