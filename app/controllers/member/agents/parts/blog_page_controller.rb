class Member::Agents::Parts::BlogPageController < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  def index
    @cur_part = @cur_part.becomes_with_route
    @items = Member::BlogPage.site(@cur_site).and_public(@cur_date).
      where(@cur_part.condition_hash(cur_path: @cur_path)).
      order_by(@cur_part.sort_hash).
      limit(@cur_part.limit)
  end
end
