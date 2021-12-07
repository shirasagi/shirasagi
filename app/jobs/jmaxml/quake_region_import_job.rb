class Jmaxml::QuakeRegionImportJob < Cms::ApplicationJob
  include SS::ZipFileImport

  private

  def model
    Jmaxml::QuakeRegion
  end

  def import_file
    SS::Csv.foreach_row(@cur_file, headers: true) do |row|
      import_row(row)
    end
    nil
  end

  def import_row(row)
    code = row[model.t(:code)].presence
    name = row[model.t(:name)].presence
    return if code.blank? || name.blank?

    item = model.site(self.site).where(code: code).first_or_create(name: name)
    item.name = name
    item.yomi = row[model.t(:yomi)].presence if row[model.t(:yomi)].present?
    item.order = row[model.t(:order)].presence if row[model.t(:order)].present?
    item.state = row[model.t(:state)].presence if row[model.t(:state)].present?
    item.save!
  end
end
