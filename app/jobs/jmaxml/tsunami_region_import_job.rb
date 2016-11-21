class Jmaxml::TsunamiRegionImportJob < Cms::ApplicationJob
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

      item = Jmaxml::TsunamiRegion.site(self.site).where(code: code).first_or_create(name: name)
      item.name = name
      item.yomi = row[:yomi].presence if row[:yomi].present?
      item.order = row[:order].presence if row[:order].present?
      item.state = row[:state].presence if row[:state].present?
      item.save!
    end
end
