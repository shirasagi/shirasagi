class Event::Agents::Pages::PageController < ApplicationController
  include Cms::PageFilter::View
  include Cms::ForMemberFilter::Page

  def index
    if @cur_page.ical_link.present?
      if Sys::TrustedUrlValidator.url_restricted? && !trusted_url?(@cur_page.ical_link)
        raise SS::NotFoundError, "url is untrusted."
      end
      request.env["ss.redirect_path"] = @cur_page.ical_link
      redirect_to @cur_page.ical_link
    end
  end
end
