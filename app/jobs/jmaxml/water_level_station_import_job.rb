class Jmaxml::WaterLevelStationImportJob < Cms::ApplicationJob
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

      item = Jmaxml::WaterLevelStation.site(self.site).where(code: code).first_or_create(name: name)
      item.name = name
      item.region_name = row[:region_name].presence if row[:region_name].present?
      item.order = row[:order].presence if row[:order].present?
      item.state = row[:state].presence if row[:state].present?
      item.save!
    end
end
