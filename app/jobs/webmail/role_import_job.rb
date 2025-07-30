class Webmail::RoleImportJob < Webmail::ApplicationJob
  include Job::SS::TaskFilter
  include SS::ZipFileImport

  self.task_name = 'webmail:role_import'

  class << self
    def valid_csv?(file)
      count = 0
      SS::Csv.foreach_row(file, headers: true) do |row|
        count += 1 if row.key?(Webmail::Role.t("id"))
        count += 1 if row.key?(Webmail::Role.t("name"))
        count += 1 if row.key?(Webmail::Role.t("permissions"))
        break
      end
      count >= 3
    rescue
      false
    end
  end

  private

  def import_file
    i = 2
    SS::Csv.foreach_row(@cur_file, headers: true) do |row|
      import_row(row, i)
      i += 1
    end
    nil
  end

  def import_row(row, index)
    id               = val(row, "id")
    name             = val(row, "name")
    permissions      = val(row, "permissions").split("\n")

    if id.present?
      item = Webmail::Role.unscoped.where(id: id).first
      if item.blank?
        Rails.logger.warn("#{index}行目: 指定された ID #{id} を持つ権限/ロールが見つからないため無視します。")
        return nil
      end

      if name.blank?
        Rails.logger.info("#{index}行目: 権限/ロール #{id} ロール名が空白のため無視します。")
        return nil
      end
    else
      item = Webmail::Role.new
    end

    item.name             = name
    item.permissions      = item.normalized_permissions(permissions)

    if !item.save
      Rails.logger.warn("#{index}行目: 権限/ロール #{id} をインポート中にエラーが発生しました。エラー:\n#{item.errors.full_messages.join("\n")}")
      return nil
    end

    Rails.logger.info("#{index}行目: 権限/ロール #{id} をインポートしました。")
    item
  end

  def val(row, key)
    row[Webmail::Role.t(key)].to_s.strip
  end
end
