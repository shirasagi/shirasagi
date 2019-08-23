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
    rescue => e
      false
    ensure
      file.rewind
    end

    def each_csv(file, &block)
      io = file.to_io
      if utf8_file?(io)
        io.seek(3)
        io.set_encoding('UTF-8')
      else
        io.set_encoding('SJIS:UTF-8')
      end

      csv = CSV.new(io, { headers: true })
      csv.each(&block)
    ensure
      io.set_encoding("ASCII-8BIT")
    end

    private

    def utf8_file?(file)
      file.rewind
      bom = file.read(3)
      file.rewind

      bom.force_encoding("UTF-8")
      SS::Csv::UTF8_BOM == bom
    end
  end
end
