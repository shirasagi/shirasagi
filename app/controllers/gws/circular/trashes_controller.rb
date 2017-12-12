class Gws::Circular::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Circular::Post

  before_action :set_item, only: [:show, :delete, :destroy, :active, :recover]
  before_action :set_selected_items, only: [:active_all, :destroy_all]
  before_action :set_category

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    set_category
    if @category.present?
      @crumbs << [I18n.t('modules.gws/circular'), gws_circular_posts_path]
      @crumbs << [t('gws/circular.admin'), gws_circular_trashes_path ]
      @crumbs << [@category.name, action: :index]
    else
      @crumbs << [I18n.t('modules.gws/circular'), gws_circular_posts_path]
      @crumbs << [t('gws/circular.admin'), gws_circular_trashes_path ]
    end
  end

  def set_category
    @categories = Gws::Circular::Category.site(@cur_site).readable(@cur_user, @cur_site).tree_sort
    if category_id = params[:category].presence
      @category ||= Gws::Circular::Category.site(@cur_site).readable(@cur_user, @cur_site).where(id: category_id).first
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
    delete_other_permission = @cur_user.gws_role_permissions["delete_other_gws_circular_posts_#{@cur_site.id}"]

    if read_other_permission && delete_other_permission
      @items = @model.site(@cur_site).
          deleted.
          search(params[:s]).
          page(params[:page]).per(50)
    else
      @items = @model.site(@cur_site).
          owner(:read, @cur_user, site: @cur_site).
          deleted.
          search(params[:s]).
          page(params[:page]).per(50)
    end

  end

  def recover
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  def active
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.active, {notice: t('gws/circular.notice.active')}
  end

  def active_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:edit, @cur_user, site: @cur_site)
        next if item.active
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end

    location = crud_redirect_url || { action: :index }
    notice = { notice: t('gws/circular.notice.active') }
    errors = @items.map { |item| [item.id, item.errors.full_messages] }

    respond_to do |format|
      format.html { redirect_to location, notice }
      format.json { head json: errors }
    end
  end
end
