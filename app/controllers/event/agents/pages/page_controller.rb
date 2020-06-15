class Event::Agents::Pages::PageController < ApplicationController
  include Cms::PageFilter::View
  include Cms::ForMemberFilter::Page

  def index
    if @cur_page.ical_link.present?
      redirect_to @cur_page.ical_link
      return
    end
    map_points
  end

  def map_points
    if @cur_page.map_points.blank? && @cur_page.facility_ids.present?
      map_points = []
      @cur_page.facility_ids.each do |facility_id|
        facility = Facility::Node::Page.site(@cur_site).and_public.where(id: facility_id).first
        items = Facility::Map.site(@cur_site).and_public.
          where(filename: /^#{::Regexp.escape(facility.filename)}\//, depth: facility.depth + 1).order_by(order: 1).first.map_points
        items.each do |item|
          marker_info = view_context.render_facility_info(facility)
          item[:html] = marker_info
          map_points << item
        end
      end
      @cur_page.map_points = map_points
    end
  end
end
