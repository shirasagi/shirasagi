module Cms::ApiFilter::Contents
  extend ActiveSupport::Concern

  HTML_FIELDS = [
    :name, :html, :question, :upper_html, :lower_html, :contact_charge, :contact_tel, :contact_fax, :contact_email
  ].freeze

  private
    def search_html_with_string(string)
      cond = { "$or" => HTML_FIELDS.map { |field| { field => /#{Regexp.escape(string)}/ } } }
      search_html_with_condition(cond)
    end

    def search_html_with_url(url)
      path = "=\"#{Regexp.escape(url)}"
      cond = { "$or" => HTML_FIELDS.map { |field| { field => /#{path}/ } } }
      search_html_with_condition(cond)
    end

    def search_html_with_regexp(string)
      regexp = Regexp.new(string, Regexp::MULTILINE)
      cond = { "$or" => HTML_FIELDS.map { |field| { field => regexp } } }
      search_html_with_condition(cond)
    end

    def search_html_with_condition(cond)
      @pages = Cms::Page.site(@cur_site).where(cond)
      @parts = Cms::Part.site(@cur_site).where(cond)
      @layouts = Cms::Layout.site(@cur_site).where(cond)
    end
end
