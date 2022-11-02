module Gws::Workload::Importer
  class Base
    include ActiveModel::Model

    attr_reader :site, :year, :user, :imported

    def model
    end

    def headers
    end

    def initialize(site, year, user)
      @site = site
      @year = year
      @user = user
    end

    def import(file)
      @imported = 0

      if file.nil? || ::File.extname(file.original_filename) != ".csv"
        errors.add :base, :invalid_csv
        return false
      end

      if !SS::Csv.valid_csv?(file, headers: true, required_headers: headers)
        errors.add :base, :malformed_csv
        return false
      end

      SS::Csv.foreach_row(file, headers: true) do |row, i|
        update_row(row, i + 2)
      end
      errors.empty?
    end

    # export
    def enum_csv(options)
      encoding = options[:encoding].presence || "Shift_JIS"
      items = export_items
      Enumerator.new do |y|
        str = encode(headers, encoding)
        str = SS::Csv::UTF8_BOM + str if encoding.casecmp("UTF-8") == 0
        y << str
        items.each do |item|
          y << encode(item_to_csv(item), encoding)
        end
      end
    end

    def export_items
    end

    def item_to_csv(item)
    end

    def encode(str, encoding)
      str = str.to_csv if str.is_a?(Array)
      str.encode(encoding, invalid: :replace, undef: :replace)
    end

    private

    def update_row(row, index)
    end

    def set_errors(item, index)
      SS::Model.copy_errors(item, self, prefix: "#{index}: ")
    end
  end
end
