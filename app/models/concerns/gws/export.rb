module Gws::Export
  extend ActiveSupport::Concern
  extend SS::Translation

  UTF8_BOM = "\uFEFF".freeze

  included do
    attr_accessor :in_file, :in_csv_encoding
    permit_params :in_file, :in_csv_encoding
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

    if in_csv_encoding.present? && in_csv_encoding.casecmp("UTF-8") == 0
      csv = UTF8_BOM + csv
    else
      csv = csv.encode("SJIS", invalid: :replace, undef: :replace)
    end

    csv
  end

  def import_csv
    validate_import_file
    return false unless errors.empty?

    field_keys = export_fields
    field_vals = export_field_names

    no = 0
    each_csv do |row|
      no += 1
      data = {}
      row.each do |k, v|
        idx = field_vals.index(k)
        data[field_keys[idx]] = v if idx
      end

      next if data.blank?
      item = import_data(data.with_indifferent_access)
      errors.add :base, "##{no} " + item.errors.full_messages.join("\n") if item.errors.present?
    end

    errors.empty?
  end

  private

  def utf8_file?
    in_file.rewind
    bom = in_file.read(3)
    in_file.rewind

    bom.force_encoding("UTF-8")
    UTF8_BOM == bom
  end

  def each_csv(&block)
    io = in_file.to_io
    if utf8_file?
      io.seek(3)
      io.set_encoding('UTF-8')
    else
      io.set_encoding('SJIS:UTF-8')
    end

    csv = CSV.new(io, { headers: true })
    csv.each(&block)
  ensure
    io.set_encoding("ASCII-8BIT")
  end

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
      no = 0
      each_csv do |row|
        no += 1
        # check csv record up to 100
        break if no >= 100
      end
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

      begin
        item.attributes = data
      rescue Mongoid::Errors::InvalidValue
        raise export_fields.inspect
      end
    else
      data.delete(:id)
      item = import_new_item(data)
    end

    item.cur_user = @cur_user
    item.cur_site = @cur_site if @cur_site
    # cur_user must be contained because some permission errors may occur if it absents.
    item.user_ids = (Array(item.user_ids) + [@cur_user.id]).uniq if item.respond_to?(:user_ids)
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
