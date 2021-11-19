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

      true
    rescue
      false
    ensure
      file.rewind
    end

    def each_csv(file, &block)
      file.to_io do |io|
        encoding = SS::Csv.detect_encoding(io)
        return if encoding != Encoding::UTF_8 && encoding != Encoding::SJIS

        io.set_encoding(encoding)
        if encoding == Encoding::UTF_8
          # try to skip the BOM
          bom = io.read(3)
          io.rewind if bom != SS::Csv::UTF8_BOM
        end

        csv = CSV.new(io, headers: true)
        csv.each(&block)
      ensure
        csv.close if csv
      end
    end
  end
end
