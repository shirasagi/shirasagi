module Cms::ApiFilter::Contents
  extend ActiveSupport::Concern

  HTML_FIELDS = [
    :name, :html, :question, :upper_html, :lower_html
  ].freeze

  CONTACT_FIELDS = [
    :contact_charge, :contact_tel, :contact_fax, :contact_email, :contact_link_url, :contact_link_name
  ].freeze

  COLUMN_VALUES_FIELDS = [
    :value, :text, :link_url, :link_label, :lists
  ].freeze

  ARRAY_FIELDS = [
    :contains_urls, :value_contains_urls, :form_contains_urls
  ].freeze

  private

  def search_html_with_string(string)
    or_cond = []
    or_cond += HTML_FIELDS.map { |field| { field => /#{::Regexp.escape(string)}/ } }
    or_cond += CONTACT_FIELDS.map { |field| { field => /#{::Regexp.escape(string)}/ } }
    or_cond += ARRAY_FIELDS.map { |field| { field => /#{::Regexp.escape(string)}/ } }
    or_cond << {
      column_values: {
        "$elemMatch" => {
          "$or"=> COLUMN_VALUES_FIELDS.map { |key| { key => { "$in" => [/#{::Regexp.escape(string)}/] } } }
        }
      }
    }
    cond = { "$or" => or_cond }
    search_html_with_condition(cond)
  end

  def search_html_with_url(url)
    path = "=\"#{::Regexp.escape(url)}"
    or_cond = []
    or_cond += HTML_FIELDS.map { |field| { field => /#{path}/ } }
    or_cond += CONTACT_FIELDS.map { |field| { field => /#{path}/ } }
    or_cond += ARRAY_FIELDS.map { |field| { field => /\A#{::Regexp.escape(url)}/ } }
    or_cond << {
      column_values: {
        "$elemMatch" => {
          "$or"=> COLUMN_VALUES_FIELDS.map { |key| { key => { "$in" => [/#{path}/] } } }
        }
      }
    }
    cond = { "$or" => or_cond }
    search_html_with_condition(cond)
  end

  def search_html_with_regexp(string)
    regexp = ::Regexp.new(string, ::Regexp::MULTILINE)
    or_cond = []
    or_cond += HTML_FIELDS.map { |field| { field => regexp } }
    or_cond += CONTACT_FIELDS.map { |field| { field => regexp } }
    or_cond += ARRAY_FIELDS.map { |field| { field => regexp } }
    or_cond << {
      column_values: {
        "$elemMatch" => {
          "$or"=> COLUMN_VALUES_FIELDS.map { |key| { key => { "$in" => [regexp] } } }
        }
      }
    }
    cond = { "$or" => or_cond }
    search_html_with_condition(cond)
  end

  def search_html_with_condition(cond)
    @pages = Cms::Page.site(@cur_site).where(cond)
    @parts = Cms::Part.site(@cur_site).where(cond)
    @layouts = Cms::Layout.site(@cur_site).where(cond)
  end
end
