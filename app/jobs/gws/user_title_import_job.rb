class Gws::UserTitleImportJob < Gws::ApplicationJob
  include Cms::CsvImportBase
  include SS::ZipFileImport

  self.required_headers = %i[code name].map { |k| Gws::UserTitle.t(k) }.freeze

  private

  def import_file
    i = 0
    self.class.each_csv(@cur_file) do |row|
      i += 1

      code = value(row, :code)
      item = Gws::UserTitle.site(site).where(code: code).first if code.present?
      item ||= Gws::UserTitle.new
      item.cur_site = site
      item.cur_user = user

      importer.import_row(row, item)
      if item.save
        Rails.logger.info("#{i.to_s(:delimited)}行目: #{item.name}(#{item.code})をインポートしました。")
      else
        Rails.logger.warn("#{i.to_s(:delimited)}行目: #{item.errors.full_messages.join("\n")}")
      end
    end
  end

  def importer
    @importer ||= SS::Csv.draw(:import, context: self, model: Gws::UserTitle) do |importer|
      importer.simple_column :code
      importer.simple_column :name
      importer.simple_column :remark
      importer.simple_column :order
      # importer.simple_column :activation_date
      # importer.simple_column :expiration_date
      importer.simple_column :presence_editable_title_ids do |row, item, head, value|
        names = to_array(value)
        titles = Gws::UserTitle.site(site).in(name: names)
        item.presence_editable_title_ids = titles.pluck(:id)
      end
    end.create
  end

  delegate :to_array, :from_label, to: SS::Csv::CsvImporter

  def value(row, key)
    key = Gws::UserTitle.t(key) if key.is_a?(Symbol)
    row[key].try(:strip)
  end
end
