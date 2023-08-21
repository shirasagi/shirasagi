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
    if params[:parent] == 'posts'
      @crumbs << [I18n.t('gws/circular.tabs.post'), gws_circular_posts_path(category: '-')]
    else
      @crumbs << [I18n.t('gws/circular.tabs.admin'), gws_circular_admins_path(category: '-')]
    end
    if @category.present?
      if params[:parent] == 'posts'
        @crumbs << [@category.name, gws_circular_posts_path(category: @category)]
      else
        @crumbs << [@category.name, gws_circular_admins_path(category: @category)]
      end
    end

    set_post
    if params[:parent] == 'posts'
      @crumbs << [@post.name, gws_circular_post_path(category: @category || '-', id: @post)]
    else
      @crumbs << [@post.name, gws_circular_admin_path(category: @category || '-', id: @post)]
    end
  end

  def set_post
    @post ||= begin
      if params[:post_id].present?
        Gws::Circular::Post.find(params[:post_id])
      elsif params[:admin_id].present?
        Gws::Circular::Post.find(params[:admin_id])
      end
    end
    @post || (raise '404')
  end

  def crud_redirect_url
    location = { action: :show, id: @item }
    location[:category] = @category if @category
    location
  end

  public

  def index
    if params[:parent] == 'posts'
      redirect_to gws_circular_post_path(id: @post, category: @category || '-')
    elsif params[:parent] == 'admins'
      redirect_to gws_circular_admin_path(id: @post, category: @category || '-')
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
    render_create @item.save && @post.set_seen!(@cur_user)
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    @post.cur_user = @cur_user
    @post.cur_site = @cur_site
    render_update @item.update && @post.set_seen!(@cur_user)
  end

  def destroy
    location = { action: :index }
    location[:category] = @category if @category
    render_destroy @item.destroy, { location: location }
  end
end
