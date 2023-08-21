class Gws::UserOccupationImportJob < Gws::ApplicationJob
  include Cms::CsvImportBase
  include SS::ZipFileImport

  self.required_headers = %i[code name].map { |k| Gws::UserOccupation.t(k) }.freeze

  private

  def import_file
    i = 0
    self.class.each_csv(@cur_file) do |row|
      i += 1

      code = value(row, :code)
      item = Gws::UserOccupation.site(site).where(code: code).first if code.present?
      item ||= Gws::UserOccupation.new
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
    @importer ||= SS::Csv.draw(:import, context: self, model: Gws::UserOccupation) do |importer|
      importer.simple_column :code
      importer.simple_column :name
      importer.simple_column :remark
      importer.simple_column :order
      # importer.simple_column :activation_date
      # importer.simple_column :expiration_date
    end.create
  end

  delegate :to_array, :from_label, to: SS::Csv::CsvImporter

  def value(row, key)
    key = Gws::UserOccupation.t(key) if key.is_a?(Symbol)
    row[key].try(:strip)
  end
end
