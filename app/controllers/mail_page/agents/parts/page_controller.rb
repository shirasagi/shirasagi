class MailPage::Agents::Parts::PageController < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  def index
    @cur_part.cur_main_path = @cur_main_path
    @items = MailPage::Page.public_list(site: @cur_site, part: @cur_part, date: @cur_date).and_arrival(@cur_date).
      order_by(@cur_part.sort_hash).
      limit(@cur_part.limit)
  end
end
