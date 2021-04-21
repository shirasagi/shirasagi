class MailPage::Agents::Parts::PageController < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  def index
    @items = MailPage::Page.public_list(site: @cur_site, part: @cur_part, date: @cur_date, request_path: @cur_main_path).
      and_arrival(@cur_date).
      order_by(@cur_part.sort_hash).
      limit(@cur_part.limit)
  end
end
