module Guide::Importer::Procedure
  extend ActiveSupport::Concern

  def import_procedures
    return false unless validate_import

    @row_index = 0
    self.class.each_csv(in_file) do |row|
      @row_index += 1
      @row = row
      save_procedure
    end

    errors.empty?
  end

  def procedures_enum
    Enumerator.new do |y|
      headers = %w(id_name name link_url order procedure_location belongings procedure_applicant remarks).map { |v| Guide::Procedure.t(v) }
      y << encode_sjis(headers.to_csv)
      Guide::Procedure.site(cur_site).node(cur_node).each do |item|
        row = []
        row << item.id_name
        row << item.name
        row << item.link_url
        row << item.order
        row << item.procedure_location
        row << item.belongings
        row << item.procedure_applicant
        row << item.remarks
        y << encode_sjis(row.to_csv)
      end
    end
  end

  def save_procedure
    id_name = @row[Guide::Procedure.t(:id_name)]

    item = Guide::Procedure.site(cur_site).node(cur_node).where(id_name: id_name).first
    item ||= Guide::Procedure.new
    item.cur_site = cur_site
    item.cur_node = cur_node
    item.cur_user = cur_user
    item.id_name = id_name

    headers = %w(name link_url order procedure_location belongings procedure_applicant remarks)
    headers.each do |k|
      item.send("#{k}=", @row[Guide::Procedure.t(k)])
    end

    if item.save
      true
    else
      message = item.errors.full_messages.join("\n")
      errors.add :base, "#{@row_index}: #{I18n.t("guide.errors.save_failed", message: message)}"
      false
    end
  end
end
