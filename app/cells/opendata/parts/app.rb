# coding: utf-8
module Opendata::Parts::App
  class EditCell < Cell::Rails
    include Cms::PartFilter::EditCell
    model Opendata::Part::App
  end

  class ViewCell < Cell::Rails
    include Cms::PartFilter::ViewCell
    helper Cms::ListHelper

    public
      def index
        @items = Opendata::App.site(@cur_site).public.
          where(@cur_part.condition_hash).
          order_by(@cur_part.sort_hash).
          page(params[:page]).
          per(@cur_part.limit)

        @items.empty? ? "" : render
      end
  end
end
