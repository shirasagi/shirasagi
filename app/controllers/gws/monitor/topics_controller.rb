class Gws::Monitor::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Monitor::TopicFilter

  private

  def set_crumbs
    set_category
    @crumbs << [@cur_site.menu_monitor_label || t("modules.gws/monitor"), gws_monitor_main_path]
    if @category.present?
      @crumbs << [@category.name, gws_monitor_topics_path]
    end
    @crumbs << [t('gws/monitor.tabs.unanswer'), action: :index]
  end

  def set_items
    @items = @model.site(@cur_site).topic
    @items = @items.and_public
    @items = @items.and_attended(@cur_user, site: @cur_site, group: @cur_group)
    @items = @items.and_unanswered(@cur_group)
    @items = @items.search(params[:s])
    @items = @items.custom_order(params.dig(:s, :sort))
    @items = @items.page(params[:page]).per(50)
  end
end
