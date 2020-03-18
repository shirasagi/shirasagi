require "csv"

class Chat::Intent::ImportJob < Cms::ApplicationJob
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
    Chat::Intent
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
    item = model.find_or_initialize_by(site_id: site.id, node_id: node.id, name: row[model.t(:name)])
    set_attributes(row, item)

    item.save ? item : raise(item.errors.full_messages.join(", "))
  end

  def value(row, key)
    row[model.t(key)].try(:strip)
  end

  def to_array(value, delim: "\n")
    value.to_s.split(delim).map(&:strip)
  end

  def set_attributes(row, item)
    item.site_id = site.id
    item.node_id = node.id
    item.name = value(row, :name)
    item.phrase = to_array(value(row, :phrase))
    item.suggest = to_array(value(row, :suggest))
    item.response = value(row, :response)
    item.site_search = value(row, :site_search)
    item.order = value(row, :order)
    item.category_ids = Chat::Category.site(site).where(node_id: node.id).in(name: to_array(value(row, :category_ids))).pluck(:id)
  end
end
