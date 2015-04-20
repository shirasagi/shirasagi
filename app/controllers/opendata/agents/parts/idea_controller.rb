class Opendata::Agents::Parts::IdeaController < ApplicationController
  include Cms::PartFilter::View
  include Opendata::UrlHelper
  helper Opendata::ListHelper

  public
    def index
      @node_url = "#{search_ideas_path}?sort=#{@cur_part.sort}"
      @rss_url = "#{search_ideas_path}rss.xml?sort=#{@cur_part.sort}"
      @items = Opendata::Idea.site(@cur_site).public.
        where(@cur_part.condition_hash).
        sort_criteria(@cur_part.sort).
        page(params[:page]).
        per(@cur_part.limit)

      render
    end
end
