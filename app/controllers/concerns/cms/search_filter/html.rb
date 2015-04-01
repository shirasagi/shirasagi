module Cms::SearchFilter::Html
  extend ActiveSupport::Concern

  HTML_FIELDS = [:html, :question, :loop_html, :upper_html, :lower_html]

  private
    def search_html_with_url(url)
      path = "=\"#{url}"
      cond  = { "$or" => HTML_FIELDS.map { |field| { field => /\Q#{path}\E/i } } }
      search_html_with_condition(cond)
    end

    def search_html_with_regexp(string)
      regexp = Regexp.new(string, Regexp::MULTILINE)
      cond  = { "$or" => HTML_FIELDS.map { |field| { field => regexp } } }
      search_html_with_condition(cond)
    end

    def search_html_with_condition(cond)
      @pages = Cms::Page.site(@cur_site).where(cond)
      @parts = Cms::Part.site(@cur_site).where(cond)
      @layouts = Cms::Layout.site(@cur_site).where(cond)
    end
end
