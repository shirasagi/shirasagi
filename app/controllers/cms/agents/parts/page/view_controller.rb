module Cms::Agents::Parts::Page
  class ViewController < ApplicationController
    include Cms::PartFilter::View
    helper Cms::ListHelper

    def index
      @items = Cms::Page.site(@cur_site).public(@cur_date).
        where(@cur_part.condition_hash).
        order_by(@cur_part.sort_hash).
        page(params[:page]).
        per(@cur_part.limit)

      render
    end
  end
end
