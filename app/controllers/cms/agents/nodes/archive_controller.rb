class Cms::Agents::Nodes::ArchiveController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper

  before_action :set_range
  before_action :becomes_with_route_node

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
        year = ymd[0..3].to_i
        month = ymd[4..5].to_i
        from = Time.zone.local(year, month, 1)
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

  public
    def index
      @items = pages.
        order_by(@cur_node.sort_hash).
        page(params[:page]).
        per(@cur_node.limit)

      render_with_pagination @items
    end

    # def rss
    #   @items = pages.
    #     order_by(publushed: -1).
    #     per(@cur_node.limit)
    #
    #   render_rss @cur_node, @items
    # end
end
