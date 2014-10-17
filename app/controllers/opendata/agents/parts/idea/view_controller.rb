module Opendata::Agents::Parts::Idea
  class ViewController < ApplicationController
    include Cms::PartFilter::View
    helper Cms::ListHelper

    public
      def index
        @items = Opendata::Idea.site(@cur_site).public.
          where(@cur_part.condition_hash).
          order_by(@cur_part.sort_hash).
          page(params[:page]).
          per(@cur_part.limit)

        render
      end
  end
end
