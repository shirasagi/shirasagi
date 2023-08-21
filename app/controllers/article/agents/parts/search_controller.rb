class Article::Agents::Parts::SearchController < ApplicationController
  include Cms::PartFilter::View
  include Cms::PublicFilter::Layout
  include Mobile::PublicFilter
  helper Cms::ListHelper

  def index
    @search_node = @cur_part.search_node.presence || @cur_part.parent
    if @search_node.blank?
      head :ok
      return
    end

    @url = mobile_path? ? ::File.join(@cur_site.mobile_url, @search_node.filename) : @search_node.url
    render
  end
end
