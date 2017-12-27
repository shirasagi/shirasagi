class Gws::Monitor::Management::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Monitor::TopicFilter

  private

  # override Gws::Monitor::TopicFilter#append_view_paths
  def append_view_paths
    append_view_path 'app/views/gws/monitor/management/main'
    super
  end

  def set_crumbs
    set_category
    @crumbs << [t("modules.gws/monitor"), gws_monitor_topics_path]
    if @category.present?
      @crumbs << [@category.name, gws_monitor_topics_path]
    end
    @crumbs << [t('ss.management'), gws_monitor_management_main_path]
    @crumbs << [t('gws/monitor.tabs.article_management'), action: :index]
  end

  def set_items
    @items = @model.site(@cur_site).topic
    @items = @items.allow(:read, @cur_user, site: @cur_site)
    @items = @items.without_deleted
    @items = @items.search(params[:s])
    @items = @items.custom_order(params.dig(:s, :sort) || 'updated_desc')
    @items = @items.page(params[:page]).per(50)
  end
end
