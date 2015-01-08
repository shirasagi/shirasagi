class Cms::Agents::Parts::PageController < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  public
    def index
      @items = Cms::Page.site(@cur_site).public(@cur_date).
        where(@cur_part.condition_hash(cur_path: @cur_path)).
        order_by(@cur_part.sort_hash).
        page(params[:page]).
        per(@cur_part.limit)
    end
end
