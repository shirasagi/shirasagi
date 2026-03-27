class Gws::Discussion::Apis::BookmarkController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Discussion::BaseFilter

  model Gws::Discussion::Post

  before_action :set_item

  private

  def set_items
    @items ||= begin
      set_forum
      @model.all.site(@cur_site).where(forum_id: @forum)
    end
  end

  public

  def index
    @bookmarker.toggle(@item)
    @bookmarker.set_bookmarks
    render html: render_bookmark_icon(@item), layout: false
  end
end
