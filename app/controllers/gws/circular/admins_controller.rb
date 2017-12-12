class Gws::Circular::AdminsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Circular::Post

  before_action :set_item, only: [:show, :edit, :update, :disable, :delete, :destroy]
  before_action :set_selected_items, only: [:disable_all, :download]
  before_action :set_category

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    { due_date: Time.zone.now + @cur_site.circular_default_due_date.day }
  end

  def set_crumbs
    set_category
    if @category.present?
      @crumbs << [@cur_site.menu_circular_label || I18n.t('modules.gws/circular'), gws_circular_posts_path]
      @crumbs << [@category.name, action: :index]
    else
      @crumbs << [@cur_site.menu_circular_label || I18n.t('modules.gws/circular'), action: :index]
    end
  end

  def set_category
    @categories = Gws::Circular::Category.site(@cur_site).readable(@cur_user, @cur_site).tree_sort
    if category_id = params[:category].presence
      @category ||= Gws::Circular::Category.site(@cur_site).readable(@cur_user, @cur_site).where(id: category_id).first
    end
  end

  def render_destroy_all(result)
    location = crud_redirect_url || { action: :index }
    notice = result ? { notice: t('gws/circular.notice.disable') } : {}
    errors = @items.map { |item| [item.id, item.errors.full_messages] }

    respond_to do |format|
      format.html { redirect_to location, notice }
      format.json { head json: errors }
    end
  end

  public

  def index
    if @category.present?
      params[:s] ||= {}
      params[:s][:site] = @cur_site
      params[:s][:category_id] = @category.id
    end

    read_other_permission = @cur_user.gws_role_permissions["read_other_gws_circular_posts_#{@cur_site.id}"]
    edit_other_permission = @cur_user.gws_role_permissions["edit_other_gws_circular_posts_#{@cur_site.id}"]

    if read_other_permission && edit_other_permission
      @items = @model.site(@cur_site).
          topic.
          without_deleted.
          search(params[:s]).
          page(params[:page]).per(50)
    else
      @items = @model.site(@cur_site).
          topic.
          allow(:read, @cur_user, site: @cur_site).
          without_deleted.
          search(params[:s]).
          and_admins(@cur_user).
          page(params[:page]).per(50)
    end
  end

  def create
    @item = @model.new get_params
    if params[:commit] == t("ss.buttons.draft_save")
      @item.state = 'closed'
    elsif params[:commit] == t("ss.buttons.publish_save")
      @item.state = 'public'
    end
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_create @item.save
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    if params[:commit] == t("ss.buttons.draft_save")
      @item.state = 'closed'
    elsif params[:commit] == t("ss.buttons.publish_save")
      @item.state = 'public'
    end
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update
  end

  def disable
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.disable, {notice: t('gws/circular.notice.disable')}
  end

  def show
    raise '403' unless @item.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def download
    raise '403' if @items.empty?

    csv = @items.
        order(updated: -1).
        to_csv.
        encode('SJIS', invalid: :replace, undef: :replace)

    send_data csv, filename: "circular_#{Time.zone.now.to_i}.csv"
  end
end
