module Cms::CsvImportBase
  extend ActiveSupport::Concern

  included do
    cattr_accessor(:required_headers) { [] }
  end

  module ClassMethods
    def valid_csv?(file, max_read_lines: nil)
      SS::Csv.valid_csv?(file, headers: true, required_headers: required_headers, max_rows: max_read_lines)
    end

    def each_csv(file, &block)
      SS::Csv.foreach_row(file, headers: true, &block)
    end
  end
end
