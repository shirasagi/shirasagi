class Opendata::Agents::Parts::Dataset::DatasetController < ApplicationController
  include Cms::PartFilter::View
  include Opendata::UrlHelper
  helper Opendata::ListHelper

  public
    def index
      @node_url = "#{search_datasets_path}?sort=#{@cur_part.sort}"
      default_options = { "sort" => "#{@cur_part.sort}" }
      @rss_path = ->(options = {}) { build_path("#{search_datasets_path}rss.xml", default_options.merge(options)) }
      @items = Opendata::Dataset.site(@cur_site).public.
        where(@cur_part.condition_hash).
        order_by(@cur_part.sort_hash).
        page(params[:page]).
        per(@cur_part.limit)

      render
    end
end
