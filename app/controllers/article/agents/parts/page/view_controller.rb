module Article::Agents::Parts::Page
  class ViewController < ApplicationController
    include Cms::PartFilter::View
    helper Cms::ListHelper

    public
      def index
        @items = Article::Page.site(@cur_site).public(@cur_date).
          where(@cur_part.condition_hash).
          order_by(@cur_part.sort_hash).
          page(params[:page]).
          per(@cur_part.limit)
      end
  end
end
