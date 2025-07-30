module Gws::Discussion::BaseFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_forum
    before_action :set_bookmarker

    helper_method :render_bookmark_icon, :portal_path
  end

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

  def set_bookmarker
    @bookmarker = Gws::Discussion::Bookmarker.new(@cur_site, @cur_user, @forum)
  end

  def portal_path
    gws_discussion_forum_portal_path
  end

  def render_bookmark_icon(post)
    if @bookmarker.active?(post)
      '<i class="material-icons md-18 active">star</i>'.html_safe
    else
      '<i class="material-icons md-18 inactive">star_border</i>'.html_safe
    end
  end
end
