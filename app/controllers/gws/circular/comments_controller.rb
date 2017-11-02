class Gws::Circular::CommentsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Circular::Comment

  before_action :set_parent

  private

  def fix_params
    { user_id: @cur_user.id, site_id: @cur_site.id, parent: @parent }
  end

  def pre_params
    { name: "Re: #{@parent.name}" }
  end

  def set_crumbs
    @crumbs << [I18n.t('modules.gws/circular'), gws_circular_posts_path]
  end

  def set_parent
    @parent ||= @model::PARENT_CLASS.find(params[:post_id])
    @parent ? @parent : (raise '404')
  end

  def crud_redirect_url
    gws_circular_post_path(id: @parent.id)
  end

  def set_item
    set_parent
    @item = @parent.comments[params[:id].to_i]
    @item.parent = @parent
    @item
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  public

  def index
    redirect_to gws_circular_post_path(id: @parent.id)
  end
  alias_method :show, :index

end
