module Cms::Michecker::Base
  extend ActiveSupport::Concern

  included do
    attr_accessor :items
  end

  module ClassMethods
    def load(filename)
      items = []
      each_line(filename) do |line|
        items.push(OpenStruct.new(::JSON.parse(line)))
      end

      new(items: items)
    end

    private

    def each_line(filename, &block)
      if filename.ends_with?(".gz")
        ::Zlib::GzipReader.open(filename) do |gz|
          gz.each_line(&block)
        end
      else
        ::File.open(filename) do |file|
          file.each_line(&block)
        end
      end
    end
  end

  def aggregate_counts
    return [ 0, 0, 0, 0 ] if items.blank?

    error_count = warning_count = caution_count = notice_count = 0

    items.each do |item|
      case item.severity
      when 1
        error_count += 1
      when 2
        warning_count += 1
      when 4
        caution_count += 1
      when 8
        notice_count += 1
      end
    end

    all_count = error_count + warning_count + caution_count + notice_count
    [ all_count, error_count, warning_count, caution_count, notice_count ]
  end
end
