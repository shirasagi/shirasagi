class Rss::WeatherXml::QuakeRegionImportJob < Cms::ApplicationJob
  include SS::ZipFileImport

  private
    def import_file
      table = ::CSV.table(@cur_file.path, encoding: 'SJIS:UTF-8')
      table.each do |row|
        import_row(row)
      end
      nil
    end

    def import_row(row)
      code = row[:code]
      name = row[:name]
      yomi = row[:yomi]

      item = Rss::WeatherXml::QuakeRegion.site(self.site).where(code: code).first_or_create
      item.name = name
      item.yomi = yomi
      item.order = code.to_i
      item.save!
    end
end
