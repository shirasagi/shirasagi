class Cms::CheckLinks::Errors
  include ActiveModel::Model
  include Enumerable

  attr_reader :errors, :base_url

  def initialize(base_url, options = {})
    @base_url = base_url
    @display_meta = (options[:display_meta] == true)
    @errors = {}
  end

  delegate :each, to: :errors

  def add_error(ref, url)
    @errors[ref] ||= []
    @errors[ref] << url
  end

  def size
    errors.size
  end

  def display_meta?
    @display_meta
  end

  def to_message
    msg = ["[#{size} errors]"]
    errors.map do |ref, urls|
      ref = File.join(base_url, ref) if ref[0] == "/"
      msg << ref
      msg << urls.map do |url|
        meta = display_meta? ? " #{url.meta}" : ""
        url = File.join(@base_url, url) if url[0] == "/"
        "  - #{url}#{meta}"
      end
    end
    msg.join("\n")
  end

  def to_csv
    csv = CSV.generate do |data|
      data << %w(reference url)
      errors.each do |ref, urls|
        urls.each do |url|
          data << [ref, url]
        end
      end
    end
    SS::Csv::UTF8_BOM + csv
  end
end
