module Opendata::Dataset::ResourceHistoryFilter
  extend ActiveSupport::Concern

  included do
    helper Opendata::ListHelper

    append_view_path "app/views/opendata/dataset/resource_history_main"
    navi_view "opendata/main/navi"
    menu_view nil

    before_action :set_search_params
    before_action :set_items

    cattr_accessor :csv_filename_base, instance_accessor: false
  end

  private

  def set_cur_ymd
    @cur_ymd ||= begin
      ymd = params[:ymd]
      raise "404" if ymd.blank? || !ymd.numeric?

      Time.zone.local(ymd[0..3].to_i, ymd[4..5].to_i, ymd[6..7].to_i)
    end
  end

  def set_search_params
    set_cur_ymd

    @s ||= begin
      s = OpenStruct.new(params[:s])
      s.cur_site = @cur_site
      s.ymd ||= @cur_ymd
      s
    end
  end

  def set_items
    @items ||= @model.site(@cur_site).search(@s).order_by(site_id: 1, @model.issued_at_field => -1)
  end

  public

  def download
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    enum = @model::HistoryCsv.enum_csv(@cur_site, @items)
    send_enum enum, type: 'text/csv; charset=Shift_JIS',
              filename: "#{self.class.csv_filename_base}_#{Time.zone.now.to_i}.csv"
  end
end
