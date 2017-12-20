require "csv"

class Cms::Role::ImportJob < Cms::ApplicationJob
  def put_log(message)
    Rails.logger.info(message)
  end

  def perform(ss_file_id)
    file = ::SS::File.find(ss_file_id)

    put_log("import start " + ::File.basename(file.name))
    import_csv(file)

    file.destroy
  end

  def model
    Cms::Role
  end

  def import_csv(file)
    table = CSV.read(file.path, headers: true, encoding: 'SJIS:UTF-8')
    table.each_with_index do |row, i|
      begin
        item = update_row(row, i + 2)
        put_log("update #{i + 1}: #{item.name}") if item.present?
      rescue => e
        put_log("error  #{i + 1}: #{e}")
      end
    end
  end

  def update_row(row, index)
    id = row[model.t(:id)]
    if id.present?
      item = model.where(site_id: site.id, id: id).first
      if item.blank?
        errors = model.new.errors.add :base, :not_found, line_no: index, id: id
        raise errors.join(", ")
      end
    else
      item = model.new
    end
    set_attributes(row, item)

    item.save ? item : raise(item.errors.full_messages.join(", "))
  end

  def value(row, key)
    row[model.t(key)].try(:strip)
  end

  def permissions_value(row, key)
    permissions = []
    model.module_permission_names(separator: true).each do |mod, names|
      names.each do |name|
        permission = "[#{model.mod_name(mod)}]#{I18n.t("#{model.collection_name.to_s.singularize}.#{name}")}"
        next unless row[model.t(key)].to_s.include? permission
        permissions.push name.to_s
      end
    end
    permissions
  end

  def set_attributes(row, item)
    item.name = value(row, :name)
    item.permissions = permissions_value(row, :permissions)
    item.site_id = value(row, :site_id)
    item.permission_level = value(row, :permission_level)
  end
end
