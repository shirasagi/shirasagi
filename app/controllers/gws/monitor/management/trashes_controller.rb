class Gws::Monitor::Management::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Monitor::Topic

  before_action :set_item, only: [
    :show, :edit, :update, :delete, :destroy, :active, :recover
  ]

  before_action :set_selected_items, only: [
      :destroy_all, :active_all
  ]

  before_action :set_category

  private

  def set_crumbs
    set_category
    if @category.present?
      @crumbs << [t("modules.gws/monitor"), gws_monitor_topics_path]
      @crumbs << [t("mongoid.models.gws/monitor/management"), gws_monitor_management_trashes_path]
      @crumbs << [@category.name, action: :index]
    else
      @crumbs << [t("modules.gws/monitor"), gws_monitor_topics_path]
      @crumbs << [t("mongoid.models.gws/monitor/management"), gws_monitor_management_trashes_path]
    end
  end

  def set_category
    @categories = Gws::Monitor::Category.site(@cur_site).readable(@cur_user, @cur_site).tree_sort
    if category_id = params[:category].presence
      @category ||= Gws::Monitor::Category.site(@cur_site).readable(@cur_user, @cur_site).where(id: category_id).first
    end
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    current_category_id = super
    if @category.present?
      current_category_id[:category_ids] = [ @category.id ]
    end
    current_category_id
  end

  public

  def index
    @items = @model.site(@cur_site).topic

    if @category.present?
      params[:s] ||= {}
      params[:s][:site] = @cur_site
      params[:s][:category] = @category.name
    end

    if @cur_user.gws_role_permissions["read_other_gws_monitor_posts_#{@cur_site.id}"] &&
      @cur_user.gws_role_permissions["delete_other_gws_monitor_posts_#{@cur_site.id}"]
      @items = @items.search(params[:s]).
          custom_order(params.dig(:s, :sort) || 'updated_desc').
          page(params[:page]).per(50)
    else
      @items = @items.search(params[:s]).
          and_admins(@cur_user).
          custom_order(params.dig(:s, :sort) || 'updated_desc').
          page(params[:page]).per(50)
    end
  end

  def show
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
    render file: "/gws/monitor/management/main/show_#{@item.mode}"
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.destroy, {notice: t('ss.notice.deleted')}
  end

  def recover
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  def active
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.active, {notice: t('gws/monitor.notice.active')}
  end

  def active_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site)
        next if item.active
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_active_all(entries.size != @items.size)
  end

  def render_active_all(result)
    location = crud_redirect_url || { action: :index }
    notice = result ? { notice: t("gws/monitor.notice.active") } : {}
    errors = @items.map { |item| [item.id, item.errors.full_messages] }

    respond_to do |format|
      format.html { redirect_to location, notice }
      format.json { head json: errors }
    end
  end
end
