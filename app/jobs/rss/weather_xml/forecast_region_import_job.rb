class Rss::WeatherXml::ForecastRegionImportJob < Cms::ApplicationJob
  include SS::ZipFileImport

  private
    def import_file
      table = ::CSV.table(@cur_file.path, encoding: 'SJIS:UTF-8')
      table.each_with_index do |row, i|
        import_row(row, i)
      end
      nil
    end

    def import_row(row, index)
      code = row[:code].presence
      name = row[:name].presence
      return if code.blank? || name.blank?

      item = Rss::WeatherXml::ForecastRegion.site(self.site).where(code: code).first_or_create(name: name)
      item.name = name
      item.yomi = row[:yomi].presence
      item.short_name = row[:short_name].presence
      item.short_yomi = row[:short_yomi].presence
      item.order = row[:order].presence
      item.state = row[:state].presence
      item.save!
    end
end
