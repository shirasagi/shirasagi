class Article::Agents::Parts::PageController < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  def index
    @items = Article::Page.public_list(site: @cur_site, part: @cur_part, date: @cur_date, request_dir: @cur_main_path)

    if @cur_part.sort_column_name.present?
      @items = @items.entries.sort_by do |a, b|
        a ? a.column_values.entries.find { |cv| cv.name == @cur_part.sort_column_name }.try(:export_csv_cell) : nil
      end
      @items.reverse! if @cur_part.sort_column_direction == "desc"
      @items.slice!(@cur_part.limit..)
    else
      @items.order_by(@cur_part.sort_hash).limit(@cur_part.limit)
    end
  end
end
