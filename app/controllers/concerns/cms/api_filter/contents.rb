module Cms::ApiFilter::Contents
  extend ActiveSupport::Concern

  HTML_FIELDS = [
    :name, :html, :question, :upper_html, :lower_html, :contact_charge, :contact_tel,
    :contact_fax, :contact_email, :contact_link_url, :contact_link_name
  ].freeze

  COLUMN_VALUES_FIELDS = [
    :value, :text, :link_url, :link_label, :lists
  ].freeze

  private

  def search_html_with_string(string)
    cond = HTML_FIELDS.map { |field| { field => /#{::Regexp.escape(string)}/ } }
    cond << {
      column_values: {
        "$elemMatch" => {
          "$or"=> COLUMN_VALUES_FIELDS.map { |key| { key => { "$in" => [/#{::Regexp.escape(string)}/] } } }
        }
      }
    }
    cond = { "$or" => cond }
    search_html_with_condition(cond)
  end

  def search_html_with_url(url)
    path = "=\"#{::Regexp.escape(url)}"
    cond = HTML_FIELDS.map { |field| { field => /#{path}/ } }
    cond << {
      column_values: {
        "$elemMatch" => {
          "$or"=> COLUMN_VALUES_FIELDS.map { |key| { key => { "$in" => [/#{path}/] } } }
        }
      }
    }
    cond = { "$or" => cond }
    search_html_with_condition(cond)
  end

  def search_html_with_regexp(string)
    regexp = ::Regexp.new(string, ::Regexp::MULTILINE)
    cond = HTML_FIELDS.map { |field| { field => regexp } }
    cond << {
      column_values: {
        "$elemMatch" => {
          "$or"=> COLUMN_VALUES_FIELDS.map { |key| { key => { "$in" => [regexp] } } }
        }
      }
    }
    cond = { "$or" => cond }
    search_html_with_condition(cond)
  end

  def search_html_with_condition(cond)
    @pages = Cms::Page.site(@cur_site).where(cond)
    @parts = Cms::Part.site(@cur_site).where(cond)
    @layouts = Cms::Layout.site(@cur_site).where(cond)
  end
end
