class Cms::Agents::Nodes::ArchiveController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper
  helper Cms::ArchiveHelper
  helper Event::EventHelper

  before_action :set_range
  before_action :becomes_with_route_node

  prepend_view_path "app/views/cms/agents/nodes/archive"

  private
    def set_range
      ymd = params[:ymd].presence
      case ymd.length
      when 4
        # year is specified
        from = Time.zone.local(ymd.to_i, 1, 1)
        to = from + 1.year - 1.second
        @range = from..to
      when 6
        # year/month is specified
        @year = ymd[0..3].to_i
        @month = ymd[4..5].to_i
        from = Time.zone.local(@year, @month, 1)
        to = from + 1.month - 1.second
        @range = from..to
      when 8
        # year/month/day is specified
        year = ymd[0..3].to_i
        month = ymd[4..5].to_i
        day = ymd[6..7].to_i
        from = Time.zone.local(year, month, day)
        to = from + 1.day - 1.second
        @range = from..to
      else
        raise "404"
      end
    rescue
      raise "404"
    end

    def becomes_with_route_node
      @cur_node = @cur_node.becomes_with_route
      @cur_parent = @cur_node.parent.try(:becomes_with_route)
    end

    def pages
      if @cur_node.conditions.present?
        condition_hash = @cur_node.condition_hash
      else
        condition_hash = @cur_parent.try(:condition_hash)
        condition_hash ||= @cur_node.condition_hash
      end

      Cms::Page.site(@cur_site).and_public(@cur_date).where(condition_hash).where(released: @range)
    end

    def set_items
      @items = pages.
        order_by(@cur_node.sort_hash).
        page(params[:page]).
        per(@cur_node.limit)
    end

    def set_contents
      @contents = {}
      if @year && @month
        start_date = Date.new(@year, @month, 1)
        close_date = start_date.end_of_month
        (start_date..close_date).each do |d|
          @contents[d] = []
        end

        dates = (start_date..close_date).map { |m| m.mongoize }
        dates.each do |time|
          d = time.to_date
          if contents_sort(time).exists?
            @contents[d] << contents_sort(time)
          end
        end
      end
    end

    def contents_sort(date)
      pages.where(:released.gte => date.getlocal.beginning_of_day, :released.lte => date.getlocal.end_of_day)
    end

  public
    def index
      set_contents if params[:ymd].length == 6
      if @cur_node.archive_view == 1
        set_items
        render_with_pagination @items
      else
        set_contents
        render template: 'monthly'
      end
    end

    # def rss
    #   @items = pages.
    #     order_by(publushed: -1).
    #     per(@cur_node.limit)
    #
    #   render_rss @cur_node, @items
    # end
end
