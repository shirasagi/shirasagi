class Rss::WeatherXml::TsunamiRegionImportJob < Cms::ApplicationJob
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
      code = row[:code].presence
      name = row[:name].presence
      return if code.blank? || name.blank?

      item = Rss::WeatherXml::TsunamiRegion.site(self.site).where(code: code, name: name).first_or_create
      item.name = row[:name].presence
      item.yomi = row[:yomi].presence
      item.order = row[:order].presence
      item.state = row[:state].presence
      item.save!
    end
end
