module Opendata::Dataset::ResourceReportFilter
  extend ActiveSupport::Concern

  included do
    append_view_path "app/views/opendata/dataset/resource_report_main"
    navi_view "opendata/main/navi"
    menu_view "opendata/dataset/resource_report_main/menu"

    before_action :set_search_params
    before_action :set_items

    cattr_accessor :csv_filename_base, instance_accessor: false
  end

  private

  def set_search_params
    @s ||= begin
      now = Time.zone.now
      s = OpenStruct.new(params[:s])
      s.cur_site = @cur_site
      s.start_year ||= now.year
      s.start_month ||= now.month
      s.end_year ||= now.year
      s.end_month ||= now.month
      s.type ||= "day"
      s
    end
  end

  def set_items
    case @s.type
    when "month"
      @items ||= @model.site(@cur_site).search(@s).aggregate_by_month
    when "year"
      @items ||= @model.site(@cur_site).search(@s).aggregate_by_year
    else
      @items ||= @model.site(@cur_site).search(@s).order_by(site_id: 1, year_month: 1, dataset_id: 1, resource_id: 1)
    end
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @items = Kaminari.paginate_array(@items) if @items.is_a?(Array)
    @items = @items.page(params[:page]).per(50)

    render file: "index"
  end

  def download
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    enum = begin
      case @s.type
      when "month"
        @model.enum_monthly_csv(@cur_site, @cur_node, @items)
      when "year"
        @model.enum_yearly_csv(@cur_site, @cur_node, @items)
      else
        @items.enum_csv(@cur_site, @cur_node)
      end
    end

    send_enum enum, type: 'text/csv; charset=Shift_JIS',
              filename: "#{self.class.csv_filename_base}_#{Time.zone.now.to_i}.csv"
  end
end
