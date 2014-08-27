# coding: utf-8
module Cms::Parts::Page
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Cms::Part::Page
  end

  class ViewCell < Cell::Rails
    include Cms::PartFilter::ViewCell
    helper Cms::ListHelper

    def index
      @items = Cms::Page.site(@cur_site).public.
        where(@cur_part.condition_hash).
        order_by(@cur_part.sort_hash).
        page(params[:page]).
        per(@cur_part.limit)

      render
    end
  end
end
