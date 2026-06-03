class Gws::Monitor::Management::TrashesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Monitor::TopicFilter

  before_action :check_readable
  navi_view "gws/monitor/main/navi"

  private

  # override Gws::Monitor::TopicFilter#append_view_paths
  def append_view_paths
    append_view_path 'app/views/gws/monitor/management/main'
    super
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_monitor_label || t("modules.gws/monitor"), gws_monitor_topics_path]
    @crumbs << [t('ss.navi.trash'), action: :index]
  end

  def set_items
    @items ||= begin
      items = @model.site(@cur_site).topic
      items = items.allow(:trash, @cur_user, site: @cur_site)
      items = items.only_deleted
      items
    end
  end

  def check_readable
    if @item
      raise '403' unless @item.allowed?(:read, @cur_user, site: @cur_site)
    end
  end
end
