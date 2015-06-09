class Opendata::Agents::Parts::Idea::IdeaController < ApplicationController
  include Cms::PartFilter::View
  include Opendata::UrlHelper
  helper Opendata::ListHelper

  public
    def index
      @node_url = "#{search_ideas_path}?sort=#{@cur_part.sort}"
      default_options = { "sort" => "#{@cur_part.sort}" }
      @rss_path = ->(options = {}) { build_path("#{search_ideas_path}rss.xml", default_options.merge(options)) }
      @items = Opendata::Idea.site(@cur_site).public.
        where(@cur_part.condition_hash).
        sort_criteria(@cur_part.sort).
        page(params[:page]).
        per(@cur_part.limit)

      render
    end
end
