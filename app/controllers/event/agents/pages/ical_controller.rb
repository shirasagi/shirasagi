class Event::Agents::Pages::IcalController < ApplicationController
  include Cms::PageFilter::View

  def index
    redirect_to @cur_page.full_url
  end
end
