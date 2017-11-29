class Gws::Circular::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Circular::Comment

  before_action :set_category
  before_action :set_post

  private

  def set_category
    if params[:category].present?
      @category ||= Gws::Circular::Category.site(@cur_site).where(id: params[:category]).first
    end
  end

  def fix_params
    set_post
    { user_id: @cur_user.id, site_id: @cur_site.id, post_id: @post.id }
  end

  def pre_params
    { name: "Re: #{@post.name}" }
  end

  def set_crumbs
    set_category
    if @category.present?
      @crumbs << [t("modules.gws/circular"), gws_circular_posts_path]
      @crumbs << [@category.name, gws_circular_category_posts_path]
    else
      @crumbs << [t("modules.gws/circular"), gws_circular_posts_path]
    end
  end

  def set_post
    @post ||= Gws::Circular::Post.find(params[:post_id])
    @post ? @post : (raise '404')
  end

  def crud_redirect_url
    gws_circular_post_path(id: @post.id)
  end

  public

  def index
    if @category.present?
      redirect_to gws_circular_category_post_path(id: @post.id)
    else
      redirect_to gws_circular_post_path(id: @post.id)
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
