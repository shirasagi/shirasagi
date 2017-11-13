class Gws::Circular::PostsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Circular::Post

  before_action :set_item, only: [:show, :edit, :update, :disable, :delete, :destroy, :set_seen, :unset_seen, :toggle_seen]
  before_action :set_selected_items, only: [:destroy_all, :disable_all, :set_seen_all, :unset_seen_all, :download]
  before_action :set_category

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_crumbs
    @crumbs << [I18n.t('modules.gws/circular'), gws_circular_posts_path]
  end

  def set_category
    cond = Gws::Circular::Category.site(@cur_site).readable(@cur_user, @cur_site)
    @categories = cond.tree_sort
    @category = cond.where(id: params[:category]).first if params[:category]
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

    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      without_deleted.
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def disable
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.disable, {notice: t('gws/circular.notice.disable')}
  end

  def show
    if @item.see_type == 'simple' && @item.unseen?(@cur_user)
      @item.set_seen(@cur_user).save
    end
    raise '403' unless @item.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def set_seen
    raise '403' unless @item.unseen?(@cur_user)
    render_update @item.set_seen(@cur_user).update
  end

  def unset_seen
    raise '403' unless @item.seen?(@cur_user)
    render_update @item.unset_seen(@cur_user).update
  end

  def toggle_seen
    raise '403' unless @item.member?(@cur_user)
    render_update @item.toggle_seen(@cur_user).update
  end

  def set_seen_all
    @items.each{ |item| item.set_seen(@cur_user).save if item.unseen?(@cur_user) }
    render_destroy_all(false)
  end

  def unset_seen_all
    @items.each{ |item| item.unset_seen(@cur_user).save if item.seen?(@cur_user) }
    render_destroy_all(false)
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
