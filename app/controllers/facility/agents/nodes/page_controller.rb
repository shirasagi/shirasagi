class Facility::Agents::Nodes::PageController < ApplicationController
  include Cms::NodeFilter::View
  helper Cms::ListHelper

  def map_pages
    Facility::Map.site(@cur_site).and_public.
      where(filename: /^#{::Regexp.escape(@cur_node.filename)}\//, depth: @cur_node.depth + 1).order_by(order: 1)
  end

  def image_pages
    Facility::Image.site(@cur_site).and_public.
      where(filename: /^#{::Regexp.escape(@cur_node.filename)}\//, depth: @cur_node.depth + 1).order_by(order: 1)
  end

  def index
    map_pages.each do |map|

      points = []
      map.map_points.each_with_index do |point, i|
        points.push point

        image_ids = @cur_node.categories.pluck(:image_id)
        points[i][:image] = SS::File.in(id: image_ids).first.try(:url)
        points[i][:html] = view_context.render_event_info(@cur_node, point)
      end
      map.map_points = points

      if @merged_map
        @merged_map.map_points += map.map_points
      else
        @merged_map = map
      end
    end

    @events = Event::Page.site(@cur_site).
      and_public.
      where(facility_ids: @cur_node.id).
      gte_event_dates(Time.zone.today)

    @events = @events.where(map_points: []).order(event_dates: "ASC")

    @summary_image = nil
    @images = []
    image_pages.each do |page|
      next if page.image.blank?

      if @summary_image
        @images.push page
      else
        @summary_image = page
      end
    end

    @items = @cur_node.notices.and_public.limit(@cur_node.notice_limit)
  end

  def notices
    @items = @cur_node.notices.and_public.
      page(params[:page]).
      per(@cur_node.limit)
  end

  def rss
    @items = @cur_node.notices.and_public.
      reorder(released: -1).
      limit(@cur_node.limit)

    render_rss @cur_node, @items
  end

  def dates_to_html(format)
    html = []

    get_event_dates.each do |range|
      cls = "event-dates"

      if range.size != 1
        range = [range.first, range.last]
        cls = "event-dates range"
      end

      range = range.map do |d|
        "<time datetime=\"#{I18n.l d.to_date, format: :iso}\">#{I18n.l d.to_date, format: format.to_sym}</time>"
      end.join("<span>#{I18n.t "event.date_range_delimiter"}</span>")

      html << "<span class=\"#{cls}\">#{range}</span>"
    end
    html.join("<br>")
  end
end
