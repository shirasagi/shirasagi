class Gws::Discussion::PortalController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Discussion::Post

  ALLOWED_MODES = %w(readable editable).freeze

  before_action :set_mode

  navi_view 'gws/discussion/main/navi'
  menu_view nil

  private

  def set_crumbs
    @crumbs << [I18n.t('modules.gws/discussion'), gws_discussion_portal_path]
  end

  def set_mode
    @mode = ALLOWED_MODES.include?(params[:mode]) ? params[:mode] : 'readable'
  end

  def forums
    if @mode == 'editable'
      @forums ||= Gws::Discussion::Forum.site(@cur_site).forum.without_deleted.allow(:read, @cur_user, site: @cur_site)
    else
      @forums ||= Gws::Discussion::Forum.site(@cur_site).forum.without_deleted.and_public.member(@cur_user)
    end
  end

  def items
    forum_ids = forums.order_by(descendants_updated: -1).limit(50).pluck(:id)
    items = @model.collection.aggregate([
      { '$match' => { site_id: @cur_site.id, forum_id: { '$in' => forum_ids }, depth: 3 } },
      { '$sort' => { descendants_updated: -1 } },
      { '$group' => { _id: '$parent_id', id: { '$first' => '$_id' } } }
    ])
    @model.in(id: items.pluck(:id))
  end

  public

  def index
    raise "403" unless Gws::Discussion::Forum.allowed?(:read, @cur_user, site: @cur_site)

    @recent_forums = forums.
      reorder(created: -1).limit(5)

    @recent_topics = Gws::Discussion::Topic.
      in(forum_id: forums.pluck(:id), depth: 2).
      order_by(created: -1).limit(5)

    @items = items.search(params[:s]).
      reorder(descendants_updated: -1).
      page(params[:page]).per(20)
  end
end
