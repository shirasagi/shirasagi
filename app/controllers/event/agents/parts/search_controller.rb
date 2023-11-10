class Event::Agents::Parts::SearchController < ApplicationController
  include Cms::PartFilter::View
  helper Event::EventHelper

  def index
    @categories = Category::Node::Base.public_list(site: @cur_site, date: @cur_date).order_by(order: 1)
    if @cur_part.cate_ids.present?
      @categories = @categories.in(id: @cur_part.cate_ids)
    end
    @event_pages = Cms::Page.public_list(site: @cur_site, ate: @cur_date).
      where('event_dates.0' => { "$exists" => true })

    facility_ids = @event_pages.pluck(:facility_id, :facility_ids).flatten.compact
    @facilities = Facility::Node::Page.public_list(site: @cur_site, date: @cur_date).
      in(id: facility_ids).
      order_by(order: 1, kana: 1, name: 1).
      to_a
  end
end
