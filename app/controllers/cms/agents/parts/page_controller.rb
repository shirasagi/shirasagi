class Cms::Agents::Parts::PageController < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  def index
    @items = Cms::Page.site(@cur_site).and_public(@cur_date).
      where(@cur_part.condition_hash(cur_main_path: @cur_main_path)).
      order_by(@cur_part.sort_hash).
      limit(@cur_part.limit)
  end
end
