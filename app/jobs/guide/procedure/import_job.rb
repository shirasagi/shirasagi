require "csv"

class Guide::Procedure::ImportJob < Cms::ApplicationJob
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
    Guide::Procedure
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
    item = model.find_or_initialize_by(site_id: site.id, name: row[model.t(:name)])
    set_attributes(row, item)

    item.save ? item : raise(item.errors.full_messages.join(", "))
  end

  def value(row, key)
    row[model.t(key)].try(:strip)
  end

  def ary_value(row, key)
    row[model.t(key)].to_s.split(/\n/).map(&:strip)
  end

  def set_question_ids(values)
    values.collect do |value|
      column = Guide::Question.find_or_initialize_by(site_id: site.id, question: value)
      column.name ||= value
      column.save!
      column.id
    end
  end

  def set_attributes(row, item)
    item.site_id = site.id
    item.name = value(row, :name)
    item.link_url = value(row, :link_url)
    item.html = value(row, :html)
    item.procedure_location = value(row, :procedure_location)
    item.belongings = value(row, :belongings)
    item.procedure_applicant = value(row, :procedure_applicant)
    item.remarks = value(row, :remarks)
    item.order = value(row, :order)
    item.question_ids = set_question_ids(ary_value(row, :question_ids))
  end
end
