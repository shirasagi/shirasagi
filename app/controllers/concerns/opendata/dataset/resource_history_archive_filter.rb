module Opendata::Dataset::ResourceHistoryArchiveFilter
  extend ActiveSupport::Concern

  included do
    append_view_path "app/views/opendata/dataset/resource_history_archive_main"
    navi_view "opendata/main/navi"
    menu_view "opendata/dataset/resource_history_archive_main/menu"

    before_action :set_search_params
    before_action :set_items
  end

  private

  def set_search_params
    @s ||= begin
      s = OpenStruct.new(params[:s])
      s.cur_site = @cur_site
      s
    end
  end

  def set_items
    @items ||= @model.site(@cur_site).allow(:read, @cur_user, site: @cur_site).search(@s)
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @items = @items.reorder(filename: -1).page(params[:page]).per(50)
    render
  end
end
