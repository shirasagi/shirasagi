class Event::Agents::Pages::PageController < ApplicationController
  include Cms::PageFilter::View
  include Cms::ForMemberFilter::Page

  def index
    if @cur_page.ical_link.present?
      redirect_to @cur_page.ical_link
      return
    end
  end
end
