class Gws::Circular::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Circular::Post

  before_action :set_item, only: [:show, :edit, :update, :active, :delete, :destroy, :set_seen, :unset_seen, :toggle_seen]
  before_action :set_selected_items, only: [:active_all, :destroy_all, :disable_all, :set_seen_all, :unset_seen_all, :download]
  before_action :set_category

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [I18n.t('modules.gws/circular'), gws_circular_posts_path]
    @crumbs << [t('gws/circular.admin'), '#' ]
  end

  def set_category
    cond = Gws::Circular::Category.site(@cur_site).readable(@cur_user, @cur_site)
    @categories = cond.tree_sort
    @category = cond.where(id: params[:category]).first if params[:category]
  end

  public

  def index
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      deleted.
      search(params[:s]).
      page(params[:page]).per(50)
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
