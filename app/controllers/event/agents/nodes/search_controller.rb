class Event::Agents::Nodes::SearchController < ApplicationController
  include Cms::NodeFilter::View
  include Event::EventHelper
  helper Event::EventHelper
  helper Cms::ListHelper

  before_action :set_params

  def index
    @items = []
    @categories = Category::Node::Base.public_list(site: @cur_site, date: @cur_date).order_by(order: 1)
    st_category_ids = @cur_node.parent.try(:st_category_ids)
    if st_category_ids.present?
      @categories = @categories.in(id: st_category_ids)
    end
    @event_pages = Cms::Page.public_list(site: @cur_site, date: @cur_date).
      where('event_dates.0' => { "$exists" => true })
    facility_ids = @event_pages.pluck(:facility_id, :facility_ids).flatten.compact
    @facilities = Facility::Node::Page.public_list(site: @cur_site, date: @cur_date).
      in(id: facility_ids).
      order_by(order: 1, kana: 1, name: 1).
      to_a
    if @keyword.present? || @category_ids.present? || @start_date.present? || @close_date.present? ||
       @facility_ids.present? || @sort.present?
      list_events
    end
  end

  private

  def set_params
    safe_params = params.permit(
      :search_keyword, :facility_id, :sort, category_ids: [], event: [ :start_date, :close_date]
    )
    @keyword = safe_params[:search_keyword].presence
    @category_ids = safe_params[:category_ids].presence || []
    @category_ids = @category_ids.map(&:to_i)
    if params[:event].present? && params[:event][0].present?
      @start_date = params[:event][0][:start_date].presence
      @close_date = params[:event][0][:close_date].presence
    end
    @start_date = Date.parse(@start_date) if @start_date.present?
    @close_date = Date.parse(@close_date) if @close_date.present?
    @facility_id = safe_params[:facility_id].presence
    if @facility_id.present?
      @facility_ids = Facility::Node::Page.public_list(site: @cur_site, date: @cur_date).
        where(id: @facility_id).
        pluck(:id)
    end
    @sort = safe_params[:sort].presence
  end

  def list_events
    @cur_node.sort = @sort if @sort.present?

    criteria = Cms::Page.site(@cur_site).and_public(@cur_date)
    criteria = criteria.search(keyword: @keyword) if @keyword.present?
    criteria = criteria.where(@cur_node.condition_hash)
    criteria = criteria.in(category_ids: @category_ids) if @category_ids.present?
    criteria = criteria.in(facility_ids: @facility_ids) if @facility_ids.present?

    if @start_date.present? && @close_date.present?
      criteria = criteria.search(dates: @start_date..@close_date)
    elsif @start_date.present?
      criteria = criteria.search(start_date: @start_date)
    elsif @close_date.present?
      criteria = criteria.search(close_date: @close_date)
    else
      criteria = criteria.exists(event_dates: 1)
    end

    @items = criteria.order_by(@cur_node.sort_hash).
      page(params[:page]).
      per(@cur_node.limit)
  end
end
