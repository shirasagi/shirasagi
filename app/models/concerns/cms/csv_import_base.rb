module Cms::CsvImportBase
  extend ActiveSupport::Concern

  included do
    cattr_accessor(:required_headers) { [] }
  end

  module ClassMethods
    def valid_csv?(file, max_read_lines: 100)
      no = 0
      each_csv(file) do |row|
        no += 1

        if !required_headers.all? { |h| row.headers.include?(h) }
          return false
        end

        # check csv record up to 100
        break if no >= max_read_lines
      end

      no != 0
    rescue
      false
    end

    def each_csv(file, &block)
      SS::Csv.each_row(file, headers: true, &block)
    end
  end
end
