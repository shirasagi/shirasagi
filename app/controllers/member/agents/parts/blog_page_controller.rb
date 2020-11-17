class Member::Agents::Parts::BlogPageController < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  def index
    @cur_part = @cur_part.becomes_with_route
    @cur_part.cur_main_path = @cur_main_path
    @items = Member::BlogPage.public_list(site: @cur_site, part: @cur_part, date: @cur_date).
      order_by(@cur_part.sort_hash).
      limit(@cur_part.limit)
  end
end
