class Event::Agents::Parts::SearchController < ApplicationController
  include Cms::PartFilter::View
  helper Event::EventHelper

  def index
    @categories = Cms::Node.site(@cur_site).in(id: @cur_part.cate_ids).sort(order: 1)
    @event_pages = Cms::Page.site(@cur_site).and_public(@cur_date).exists(event_dates: 1)

    facility_ids = @event_pages.pluck(:facility_id, :facility_ids).flatten.compact
    @facilities = Facility::Node::Page.site(@cur_site).and_public.
      in(id: facility_ids).order_by(order: 1, kana: 1, name: 1).to_a
  end
end
