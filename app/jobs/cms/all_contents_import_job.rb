class Cms::AllContentsImportJob < Cms::ApplicationJob
  include Job::SS::TaskFilter
  include SS::ZipFileImport

  self.task_class = Cms::Task
  self.task_name = "cms:all_contents"

  private

  def import_file
    table = ::CSV.table(@cur_file.path, converters: nil, encoding: 'SJIS:UTF-8')
    table.each do |row|
      import_row(row)
    end
    nil
  end

  def import_row(row)
    # code = row[:code].presence
    # name = row[:name].presence
    # return if code.blank? || name.blank?
    #
    # item = Jmaxml::QuakeRegion.site(self.site).where(code: code).first_or_create(name: name)
    # item.name = name
    # item.yomi = row[:yomi].presence if row[:yomi].present?
    # item.order = row[:order].presence if row[:order].present?
    # item.state = row[:state].presence if row[:state].present?
    # item.save!
  end
end
