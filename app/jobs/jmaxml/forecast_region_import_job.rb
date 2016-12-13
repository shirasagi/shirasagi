class Jmaxml::ForecastRegionImportJob < Cms::ApplicationJob
  include SS::ZipFileImport

  private
    def import_file
      table = ::CSV.table(@cur_file.path, converters: nil, encoding: 'SJIS:UTF-8')
      table.each_with_index do |row, i|
        import_row(row, i)
      end
      nil
    end

    def import_row(row, index)
      code = row[:code].presence
      name = row[:name].presence
      return if code.blank? || name.blank?

      item = Jmaxml::ForecastRegion.site(self.site).where(code: code).first_or_create(name: name)
      item.name = name
      item.yomi = row[:yomi].presence if row[:yomi].present?
      item.short_name = row[:short_name].presence if row[:short_name].present?
      item.short_yomi = row[:short_yomi].presence if row[:short_yomi].present?
      item.order = row[:order].presence if row[:order].present?
      item.state = row[:state].presence if row[:state].present?
      item.save!
    end
end
