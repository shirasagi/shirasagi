class Opendata::Agents::Parts::AppController < ApplicationController
  include Cms::PartFilter::View
  helper Opendata::ListHelper

  public
    def index
      @items = Opendata::App.site(@cur_site).public.
        where(@cur_part.condition_hash).
        order_by(@cur_part.sort_hash).
        page(params[:page]).
        per(@cur_part.limit)

      render
    end
end
