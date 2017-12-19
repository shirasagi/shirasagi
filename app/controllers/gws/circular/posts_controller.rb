class Gws::Circular::PostsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Circular::Post

  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :set_seen, :unset_seen, :toggle_seen]
  before_action :set_selected_items, only: [:destroy_all, :set_seen_all, :unset_seen_all,]
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

  public

  def index
    if @category.present?
      params[:s] ||= {}
      params[:s][:site] = @cur_site
      params[:s][:category_id] = @category.id
    end

    @items = @model.site(@cur_site).
      topic.
      allow(:read, @cur_user, site: @cur_site).
      without_deleted.
      search(params[:s]).
      and_posts(@cur_user.id, params.dig(:s, :article_state) || 'both').
      page(params[:page]).per(50)
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
end
