class Rss::WeatherXml::ForecastRegionImportJob < Cms::ApplicationJob
  include SS::ZipFileImport

  private
    def import_file
      table = ::CSV.read(@cur_file.path, headers: true, encoding: 'SJIS:UTF-8')
      table.each_with_index do |row, i|
        import_row(row, i)
      end
      nil
    end

    def import_row(row, index)
      code = row[0]
      name = row[1]
      yomi = row[2]
      short_name = row[3]
      short_yomi = row[4]

      item = Rss::WeatherXml::ForecastRegion.site(self.site).where(code: code).first_or_create
      item.name = name
      item.yomi = yomi
      item.short_name = short_name
      item.short_yomi = short_yomi
      item.save!
    end
end
