class Gws::Discussion::Thread::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Discussion::BaseFilter

  model Gws::Discussion::Topic

  before_action :set_crumbs
  before_action :set_item

  helper_method :index_path

  navi_view "gws/discussion/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, forum_id: @forum.id, parent_id: @forum.id }
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_discussion_label || I18n.t('modules.gws/discussion'), gws_discussion_forums_path ]
    @crumbs << [ @forum.name, gws_discussion_forum_portal_path ]
  end

  def index_path
    gws_discussion_forum_thread_comments_path(topic_id: @item)
  end

  def crud_redirect_url
    index_path
  end

  public

  def copy
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    if request.get? || request.head?
      prefix = I18n.t("workflow.cloned_name_prefix")
      @item.name = "[#{prefix}] #{@item.name}"
      return
    end

    @item.attributes = get_params
    if @item.valid?
      item = @item.save_clone(@topic)
      item.attributes = get_params
      render_create true, location: portal_path, render: { template: "copy" }
    else
      render_create false, location: portal_path, render: { template: "copy" }
    end
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.destroy, location: portal_path
  end
end
