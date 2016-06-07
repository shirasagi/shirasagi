class Member::Agents::Nodes::PhotoSearchController < ApplicationController
  include Cms::NodeFilter::View

  model Member::Photo

  helper Cms::ListHelper

  before_action :set_query

  private
    def set_query
      @locations  = Member::Node::PhotoLocation.site(@cur_site).and_public
      @categories = Member::Node::PhotoCategory.site(@cur_site).and_public
      @query      = query
    end

    def query
      location_ids = params[:location_ids].select(&:present?).map(&:to_i) rescue []
      category_ids = params[:category_ids].select(&:present?).map(&:to_i) rescue []
      locations    = @locations.in(id: location_ids)
      categories   = @categories.in(id: category_ids)
      {
        keyword: params[:keyword],
        contributor: params[:contributor],
        location_ids: location_ids,
        category_ids: category_ids,
        locations: locations,
        categories: categories,
      }
    end

  public
    def index
      @items = @model.site(@cur_site).and_public.
        listable.
        contents_search(@query).
        order_by(@cur_node.sort_hash).
        page(params[:page]).
        per(@cur_node.limit)
    end

    def map
      @items = @model.site(@cur_site).and_public.
        listable.
        where(:map_points.exists => true).
        contents_search(@query).
        order_by(@cur_node.sort_hash).
        page(params[:page]).
        per(@cur_node.limit)
      @markers = @items.map { |item| item.map_points }.flatten
    end
end
