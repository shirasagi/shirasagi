class Gws::Discussion::BookmarksController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Discussion::BaseFilter

  model Gws::Discussion::Post

  before_action :set_crumbs

  navi_view "gws/discussion/main/navi"

  private

  def set_forum
    raise "403" unless Gws::Discussion::Forum.allowed?(:read, @cur_user, site: @cur_site)
    @forum = Gws::Discussion::Forum.find(params[:forum_id])

    if @forum.state == "closed"
      permitted = @forum.allowed?(:read, @cur_user, site: @cur_site)
    else
      permitted = @forum.allowed?(:read, @cur_user, site: @cur_site) || @forum.member?(@cur_user)
    end

    raise "403" unless permitted
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_discussion_label || I18n.t('modules.gws/discussion'), gws_discussion_forums_path ]
    @crumbs << [ @forum.name, gws_discussion_forum_topics_path ]
    @crumbs << [ I18n.t("gws/discussion.navi.bookmark.readable"), { action: :index }]
  end

  public

  def index
    @bookmarks = @bookmarker.bookmarks.values
    @bookmarks = Kaminari.paginate_array(@bookmarks).page(params[:page]).per(50)
  end
end
