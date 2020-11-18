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
      io = file.to_io
      if valid_encoding?(io, Encoding::UTF_8)
        io.set_encoding(Encoding::UTF_8)
      elsif valid_encoding?(io, Encoding::SJIS)
        io.set_encoding(Encoding::SJIS, Encoding::UTF_8)
      end

      csv = CSV.new(io, { headers: true })
      csv.each(&block)
    ensure
      io.set_encoding(Encoding::ASCII_8BIT)
    end

    def valid_encoding?(file, encoding)
      file.rewind
      if encoding == Encoding::UTF_8
        bom = file.read(3)
        bom.force_encoding(encoding)
        return true if SS::Csv::UTF8_BOM == bom
        file.rewind
      end
      body = file.gets(1000)
      file.rewind
      body.force_encoding(encoding).valid_encoding?
    end
  end
end
