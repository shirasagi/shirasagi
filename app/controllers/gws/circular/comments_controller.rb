class Gws::Circular::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Circular::Comment

  before_action :set_category
  before_action :set_post

  navi_view "gws/circular/main/navi"

  private

  def set_category
    if params[:category].present?
      @category ||= Gws::Circular::Category.site(@cur_site).where(id: params[:category]).first
    end
  end

  def fix_params
    set_post
    if params[:post_id].present?
      { user_id: @cur_user.id, site_id: @cur_site.id, post_id: @post.id }
    elsif params[:admin_id].present?
      { user_id: @cur_user.id, site_id: @cur_site.id, post_id: @post.id }
    end
  end

  def pre_params
    { name: "Re: #{@post.name}" }
  end

  def set_crumbs
    set_category
    @crumbs << [t("modules.gws/circular"), gws_circular_main_path]
    if @category.present?
      if params[:parent] == 'posts'
        @crumbs << [@category.name, gws_circular_posts_path]
        @crumbs << [I18n.t('gws/circular.tabs.post'), action: :index]
      else
        @crumbs << [@category.name, gws_circular_admins_path]
      end
    end
    if params[:parent] == 'posts'
      @crumbs << [I18n.t('gws/circular.tabs.post'), gws_circular_posts_path]
    else
      @crumbs << [I18n.t('gws/circular.tabs.admin'), gws_circular_admins_path]
    end
  end

  def set_post
    if params[:post_id].present?
      @post ||= Gws::Circular::Post.find(params[:post_id])
    elsif params[:admin_id].present?
      @post ||= Gws::Circular::Post.find(params[:admin_id])
    end
    @post ? @post : (raise '404')
  end

  def crud_redirect_url
    if params[:post_id].present?
      gws_circular_post_path(id: @post.id)
    elsif params[:admin_id].present?
      gws_circular_admin_path(id: @post.id)
    end
  end

  public

  def index
    if params[:parent] == 'posts'
      redirect_to gws_circular_post_path(id: @post.id)
    elsif params[:parent] == 'admins'
      redirect_to gws_circular_admin_path(id: @post.id)
    end
  end
  alias show index

  def new
    @item = @model.new pre_params.merge(fix_params)
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site) || @item.post.member?(@cur_user)
  end

  def create
    @item = @model.new get_params
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site) || @item.post.member?(@cur_user)
    @post.cur_user = @cur_user
    @post.cur_site = @cur_site
    location = { action: :show, id: @item, category: @category.id } if @category
    render_create @item.save && @post.set_seen(@cur_user).save, { location: location }
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    @post.cur_user = @cur_user
    @post.cur_site = @cur_site
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    location = { action: :show, category: @category.id } if @category
    render_update @item.update && @post.set_seen(@cur_user).save, { location: location }
  end

  def destroy
    location = { action: :index, category: @category.id } if @category
    render_destroy @item.destroy, { location: location, notice: t("ss.notice.deleted") }
  end
end
