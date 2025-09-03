class Cms::Agents::Parts::FormSearchController < ApplicationController
  include Cms::PartFilter::View
  include Cms::PublicFilter::Layout
  include Mobile::PublicFilter
  helper Cms::ListHelper

  private

  def set_search_params
    @s ||= OpenStruct.new(params[:s])
  end

  public

  def index
    @search_node = @cur_part.search_node.presence || @cur_part.parent
    if @search_node.blank?
      head :ok
      return
    end

    set_search_params

    @url = mobile_path? ? ::File.join(@cur_site.mobile_url, @search_node.filename) : @search_node.url
    render
  end
end
