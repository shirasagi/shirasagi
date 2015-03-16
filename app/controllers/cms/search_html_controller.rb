class Cms::SearchHtmlController < ApplicationController
  include Cms::SearchFilter
  include Cms::SearchFilter::Html

  public
    def index
      keyword = params[:s].try(:[], :keyword)
      option   = params[:s].try(:[], :option)

      return if keyword.blank?
      begin
        if option == "regexp"
          search_html_with_regexp(keyword)
        else
          search_html_with_url(keyword)
        end

        @pages   = @pages.order_by(filename: 1).limit(500)
        @layouts = @layouts.order_by(filename: 1).limit(500)
        @parts   = @parts.order_by(filename: 1).limit(500)
      rescue RegexpError => e
        @pages   = []
        @parts   = []
        @layouts = []
      end
    end
end
