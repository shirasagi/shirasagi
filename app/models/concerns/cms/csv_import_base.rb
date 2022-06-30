module Cms::CsvImportBase
  extend ActiveSupport::Concern

  included do
    cattr_accessor(:required_headers, instance_accessor: false) { [] }
  end

  module ClassMethods
    def valid_csv?(file, max_read_lines: nil)
      if required_headers.respond_to?(:call)
        headers = class_exec(&required_headers)
      else
        headers = required_headers
      end

      SS::Csv.valid_csv?(file, headers: true, required_headers: headers, max_rows: max_read_lines)
    end

    def each_csv(file, &block)
      SS::Csv.foreach_row(file, headers: true, &block)
    end
  end
end
