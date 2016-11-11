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
      code = row[:code].presence
      name = row[:name].presence
      return if code.blank? || name.blank?

      item = Rss::WeatherXml::QuakeRegion.site(self.site).where(code: code).first_or_create(name: name)
      item.name = name
      item.yomi = row[:yomi].presence
      item.order = row[:order].presence
      item.state = row[:state].presence
      item.save!
    end
end
