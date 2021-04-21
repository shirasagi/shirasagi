class Faq::Agents::Parts::SearchController < ApplicationController
  include Cms::PartFilter::View
  include Cms::PublicFilter::Layout
  include Mobile::PublicFilter
  helper Cms::ListHelper

  def index
    @search_node = @cur_part.search_node.present? ? @cur_part.search_node : @cur_part.parent
    if @search_node.blank?
      head :ok
      return
    end

    @search_node = @search_node.becomes_with_route rescue @search_node
    @url = mobile_path? ? ::File.join(@cur_site.mobile_url, @search_node.filename) : @search_node.url
    render
  end
end
