class Gws::Monitor::Management::AdminsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Monitor::TopicFilter
  include Gws::Memo::NotificationFilter

  before_action :check_readable
  navi_view "gws/monitor/main/navi"

  private

  # override Gws::Monitor::TopicFilter#append_view_paths
  def append_view_paths
    append_view_path 'app/views/gws/monitor/management/main'
    super
  end

  def set_crumbs
    set_category
    @crumbs << [@cur_site.menu_monitor_label || t("modules.gws/monitor"), gws_monitor_topics_path]
    if @category.present?
      @crumbs << [@category.name, gws_monitor_topics_path]
    end
    @crumbs << [t('gws/monitor.tabs.article_management'), action: :index]
  end

  def set_items
    @items = @model.site(@cur_site).topic
    @items = @items.allow(:read, @cur_user, site: @cur_site)
    @items = @items.without_deleted
    @items = @items.search(params[:s])
    @items = @items.custom_order(params.dig(:s, :sort))
    @items = @items.page(params[:page]).per(50)
  end

  def check_readable
    if @item
      raise '403' unless @item.allowed?(:read, @cur_user, site: @cur_site)
    end
  end
end
