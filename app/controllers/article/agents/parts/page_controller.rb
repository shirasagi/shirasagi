class Article::Agents::Parts::PageController < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  def index
    @items = Article::Page.public_list(site: @cur_site, part: @cur_part, date: @cur_date, request_dir: @cur_main_path)

    if @cur_part.sort_column_name.present?
      @items = @cur_part.sort_by_column_name(@items).slice(0, @cur_part.limit)
    else
      @items = @items.order_by(@cur_part.sort_hash).limit(@cur_part.limit)
    end
  end
end
