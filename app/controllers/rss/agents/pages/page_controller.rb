class Rss::Agents::Pages::PageController < ApplicationController
  include Cms::PageFilter::View

  def index
    if @cur_page.rss_link.present?
      if Sys::TrustedUrlValidator.url_restricted? && !trusted_url?(@cur_page.rss_link)
        raise SS::NotFoundError, "url is untrusted."
      end
      redirect_to @cur_page.rss_link
    end
  end
end
