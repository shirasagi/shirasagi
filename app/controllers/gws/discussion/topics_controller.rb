class Gws::Discussion::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Discussion::BaseFilter

  model Gws::Discussion::Topic

  before_action :set_crumbs
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :copy]

  navi_view "gws/discussion/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, forum_id: @forum.id, parent_id: @forum.id }
  end

  def set_crumbs
    @crumbs << [ @cur_site.menu_discussion_label || I18n.t('modules.gws/discussion'), gws_discussion_forums_path ]
    @crumbs << [ @forum.name, gws_discussion_forum_portal_path ]
  end

  def set_items
    @items = @model.in(id: @forum.children.pluck(:id)).
      reorder(order: 1, created: 1).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  public

  def index
    set_items
  end

  def show
    render
  end

  def create
    @item = @model.new get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    if @item.save
      @item.save_notify_message(@cur_site, @cur_user)
      render_create true
    else
      render_create false
    end
  end

  def copy
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    if request.get? || request.head?
      prefix = I18n.t("workflow.cloned_name_prefix")
      @item.name = "[#{prefix}] #{@item.name}"
      return
    end

    @item.attributes = get_params
    if @item.valid?
      item = @item.save_clone(@forum)
      item.attributes = get_params
      render_create true, location: { action: :index }, render: { template: "copy" }
    else
      render_create false, location: { action: :index }, render: { template: "copy" }
    end
  end
end
