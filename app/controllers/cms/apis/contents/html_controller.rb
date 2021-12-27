class Cms::Apis::Contents::HtmlController < ApplicationController
  include Cms::ApiFilter
  include Cms::ApiFilter::Contents

  def index
    keyword = params[:s].try(:[], :keyword)
    option   = params[:s].try(:[], :option)

    @pages   = []
    @parts   = []
    @layouts = []

    return if keyword.blank?
    begin
      if option == "regexp"
        search_html_with_regexp(keyword)
      elsif option == "url"
        search_html_with_url(keyword)
      else
        search_html_with_string(keyword)
      end

      @pages   = @pages.order_by(filename: 1).limit(500)
      @layouts = @layouts.order_by(filename: 1).limit(500)
      @parts   = @parts.order_by(filename: 1).limit(500)
    rescue => e
    end
  end
end
