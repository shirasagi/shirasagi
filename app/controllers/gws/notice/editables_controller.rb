class Gws::Notice::EditablesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  helper Gws::Notice::PlanHelper

  before_action :set_folders
  before_action :set_folder
  before_action :set_my_folder
  before_action :set_categories
  before_action :set_category
  before_action :set_search_params
  before_action :set_items
  before_action :set_item, only: [:show, :edit, :update, :soft_delete, :move, :copy]
  before_action :set_selected_items, only: [:destroy_all, :soft_delete_all]
  before_action :set_default_readable_setting, only: [:new]

  model Gws::Notice::Post

  navi_view "gws/notice/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_notice_label || t('modules.gws/notice'), gws_notice_main_path]
    @crumbs << [t('ss.navi.editable'), action: :index, folder_id: '-', category_id: '-']
  end

  def pre_params
    {
      folder: @folder
    }
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_folders
    @folders ||= Gws::Notice::Folder.for_post_editor(@cur_site, @cur_user)
  end

  def set_folder
    return if params[:folder_id].blank? || params[:folder_id] == '-'
    @folder ||= @folders.find(params[:folder_id])
  end

  def set_my_folder
    @my_folder ||= @folders.where(name: @cur_group.name).first
    @my_folder_exists = Gws::Notice::Folder.site(@cur_site).where(name: @cur_group.name).present?
  end

  def set_categories
    @categories ||= Gws::Notice::Category.site(@cur_site).readable(@cur_user, site: @cur_site)
  end

  def set_category
    return if params[:category_id].blank? || params[:category_id] == '-'
    @category ||= @categories.find(params[:category_id])
    raise '403' unless @category.readable?(@cur_user) || @category.allowed?(:read, @cur_user, site: @cur_site)
  end

  def set_search_params
    @s = OpenStruct.new(params[:s])
    if @folder.present?
      @s[:folder_ids] = [ @folder.id ]
      @s[:folder_ids] += @folder.folders.for_post_editor(@cur_site, @cur_user).pluck(:id)
    end

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

  def set_default_readable_setting
    @default_readable_setting = proc do
      @item.readable_setting_range = @folder.readable_setting_range
      @item.readable_group_ids = @folder.readable_group_ids
      @item.readable_member_ids = @folder.readable_member_ids
      @item.readable_custom_group_ids = @folder.readable_custom_group_ids
    end
  end

  public

  def index
    @categories = @categories.tree_sort
    @items = @items.page(params[:page]).per(50)
  end

  def new
    if !@folder.member_user?(@cur_user)
      redirect_to({ action: :index }, { notice: t('gws/notice.notice.not_a_member_in_this_folder') })
      return
    end

    super
  end

  def create
    if !params[:copy] && !@folder.member_user?(@cur_user)
      redirect_to({ action: :index }, { notice: t('gws/notice.notice.not_a_member_in_this_folder') })
      return
    end

    super
  end

  def move
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    if request.get? || request.head?
      render
      return
    end

    @item.attributes = get_params
    render_update @item.save
  end

  def create_my_folder
    raise '403' if !Gws::Notice::Folder.allowed?(:my_folder, @cur_user, site: @cur_site)

    if request.get? || request.head?
      render
      return
    end

    folder = Gws::Notice::Folder.create_my_folder!(@cur_site, @cur_group)
    render_opts = {
      location: url_for(action: :index, folder_id: folder)
    }
    render_create true, render_opts
  rescue => e
    logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    render_opts = {
      render: { template: "create_my_folder" }
    }
    render_create false, render_opts
  end

  def copy
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    @item = @item.new_clone
    render template: "new"
  end
end
