class Ads::Agents::Pages::BannerController < ApplicationController
  include Cms::PageFilter::View

  def index
    raise ::SS::NotFoundError if @cur_page.link_url.blank? || @cur_page.link_url == '#'
    raise ::SS::NotFoundError unless UrlValidator.valid?(@cur_page.link_url, absolute_path: true)

    @cur_page.layout_id = nil
    render formats: %i[html]
  end
end
