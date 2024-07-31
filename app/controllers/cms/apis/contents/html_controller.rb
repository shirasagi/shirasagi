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

    if (@frame_id = request.headers["HTTP_TURBO_FRAME"]).present?
      render layout: "ss/item_frame"
    else
      render
    end
  rescue => e
    logger.info("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end
end
