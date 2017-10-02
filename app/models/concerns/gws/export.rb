module Gws::Export
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    attr_accessor :in_file
    permit_params :in_file
  end

  def export_csv(items)
    fields = export_fields

    csv = CSV.generate do |data|
      data << export_field_names
      items.each do |item|
        line = fields.map { |k| item.send(k) }
        data << export_convert_item(item, line)
      end
    end

    csv.encode("SJIS", invalid: :replace, undef: :replace)
  end

  def import_csv
    validate_import_file
    return false unless errors.empty?

    field_keys = export_fields
    field_vals = export_field_names

    rows = []
    CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8').each do |row|
      data = {}
      row.each do |k, v|
        idx = field_vals.index(k)
        data[field_keys[idx]] = v if idx
      end
      rows << data
    end

    import_array(rows)
  end

  def import_array(rows)
    rows.each_with_index do |data, no|
      next if data.blank?
      item = import_data(data.with_indifferent_access)
      errors.add :base, "##{no} " + item.errors.full_messages.join("\n") if item.errors.present?
    end
    return errors.empty?
  end

  private

  def export_fields
    fields = self.class.fields.keys
    idx = fields.index('_id')
    fields[idx] = 'id' if idx
    fields
  end

  def export_field_names
    export_fields.map { |k| t(k) }
  end

  def export_convert_item(item, line)
    line
  end

  def validate_import_file
    return errors.add :in_file, :blank if in_file.blank?

    fname = in_file.original_filename
    return errors.add :in_file, :invalid_file_type if ::File.extname(fname) !~ /^\.csv$/i

    begin
      CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
      in_file.rewind
    rescue => e
      errors.add :in_file, :invalid_file_type
    end
  end

  def import_data(data)
    data = import_convert_data(data)

    if data[:id].present?
      item = import_find_item(data)

      if item.blank?
        item = self.class.new
        item.errors.add :base, "Could not find ##{data[:id]}"
        return item
      end
      if !item.allowed?(:edit, @cur_user, site: @cur_site)
        item.errors.add :base, I18n.t('errors.messages.auth_error')
        return item
      end

      item.attributes = data
    else
      data.delete(:id)
      item = import_new_item(data)
      item.user_ids = [@cur_user.id] if item.respond_to?(:user_ids)
    end

    item.cur_user = @cur_user
    item.cur_site = @cur_site if @cur_site
    item.save
    item
  end

  def import_convert_data(data)
    data
  end

  def import_find_item(data)
    self.class.site(@cur_site).allow(:read, @cur_user, site: @cur_site).where(id: data[:id]).first
  end

  def import_new_item(data)
    self.class.new(data)
  end
end
