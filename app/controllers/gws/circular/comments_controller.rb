class Gws::Circular::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Circular::Comment

  before_action :set_post

  private

  def fix_params
    set_post
    { user_id: @cur_user.id, site_id: @cur_site.id, post_id: @post.id }
  end

  def pre_params
    { name: "Re: #{@post.name}" }
  end

  def set_crumbs
    @crumbs << [I18n.t('modules.gws/circular'), gws_circular_posts_path]
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
    redirect_to gws_circular_post_path(id: @post.id)
  end
  alias show index

  def new
    @item = @model.new pre_params.merge(fix_params)
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site) || @item.post.member?(@cur_user)
  end

  def create
    @item = @model.new get_params
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site) || @item.post.member?(@cur_user)
    render_create @item.save && @post.set_seen(@cur_user).save
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update && @post.set_seen(@cur_user).save
  end

end
