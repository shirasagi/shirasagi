class Event::Agents::Pages::PageController < ApplicationController
  include Cms::PageFilter::View
  include Cms::ForMemberFilter::Page

  def index
    if @cur_page.ical_link.present?
      unless UrlValidator.valid?(@cur_page.ical_link, absolute_path: true)
        raise SS::NotFoundError, "url is invalid."
      end
      if Sys::TrustedUrlValidator.url_restricted? && !trusted_url?(@cur_page.ical_link)
        raise SS::NotFoundError, "url is untrusted."
      end
      request.env["ss.redirect_path"] = @cur_page.ical_link
      redirect_to @cur_page.ical_link
      return
    end

    super
  end
end
