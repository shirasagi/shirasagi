class Event::Agents::Nodes::SearchController < ApplicationController
  include Cms::NodeFilter::View
  include Event::EventHelper
  helper Event::EventHelper
  helper Cms::ListHelper

  before_action :set_params

  def index
    @categories = []
    @items = []
    if @cur_node.parent
      @categories = Cms::Node.site(@cur_site).where({:id.in => @cur_node.parent.st_category_ids}).sort(filename: 1)
    end
    if @keyword.present? || @category_ids.present? || @start_date.present? || @close_date.present? || @facility_ids.present?
      list_events
    end
    @facilities = Facility::Node::Page.site(@cur_site).and_public
  end

  private

  def set_params
    safe_params = params.permit(:search_keyword, :facility_id, category_ids: [], event: [ :start_date, :close_date])
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
      @facility_ids = Facility::Node::Page.site(@cur_site).where(id: @facility_id).and_public.pluck(:id)
    end
  end

  def list_events
    criteria = Cms::Page.site(@cur_site).and_public
    criteria = criteria.search(keyword: @keyword) if @keyword.present?
    criteria = criteria.where(@cur_node.condition_hash)
    criteria = criteria.in(category_ids: @category_ids) if @category_ids.present?
    criteria = criteria.in(facility_ids: @facility_ids) if @facility_id.present?

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
