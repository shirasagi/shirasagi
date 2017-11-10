module Webmail::AccountExport
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
        line = fields.map { |k| attribute_with_export_field(item, k) }
        data << line
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

  def account_fields
    %w(
      address imap_host imap_auth_type imap_account in_imap_password
      threshold_mb imap_sent_box imap_draft_box imap_trash_box
    )
  end

  def export_fields
    fields = []
    fields << "id"
    SS.config.webmail.imap_account_limit.times do |i|
      account_fields.each do |v|
        fields << "imap_settings.#{i}.#{v}"
      end
    end
    fields
  end

  def export_field_names
    fields = []
    fields << "id"
    SS.config.webmail.imap_account_limit.times do |i|
      account_fields.each do |v|
        v = v.sub(/^[^\.]+\./, "")
        fields << "#{t(v)}#{i + 1}"
      end
    end
    fields
  end

  def attribute_with_export_field(item, field)
    if field =~ /^imap_settings\./
      s, i, at = field.split(/\./)
      i = i.to_i
      setting = item.send(s)[i]
      setting.send(at) rescue nil
    else
      item.send(field)
    end
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
    item = import_find_item(data) if data[:id].present?

    if item.blank?
      item = self.class.new
      item.errors.add :base, "Could not find ##{data[:id]}"
      return item
    end

    if !item.allowed?(:edit, @cur_user)
      item.errors.add :base, I18n.t('errors.messages.auth_error')
      return item
    end

    imap_settings = item.imap_settings
    imap_setting_errors = []
    data[:imap_settings].each_with_index do |setting, i|
      next unless setting

      if setting.valid?
        old_password = imap_settings[i].imap_password rescue nil
        setting[:imap_password] = old_password if old_password

        imap_settings[i] = setting
      else
        imap_setting_errors << [:base, I18n.t("errors.messages.imap_setting_validation_error", no: i + 1)]
      end
    end
    item.imap_settings = imap_settings

    item.cur_user = @cur_user
    item.cur_site = @cur_site if @cur_site
    item.save

    imap_setting_errors.each { |e| item.errors.add(*e) }

    item
  end

  def import_convert_data(data)
    h = {}
    imap_settings = []
    data.each do |k, v|
      if k =~ /^imap_settings\./
        s, i, at = k.split(/\./)
        i = i.to_i

        if v.present?
          imap_settings[i] ||= Webmail::ImapSetting.new
          imap_settings[i][at.to_sym] = v
        end
      else
        h[k] = v
      end
    end
    h[:id] = data[:id]
    h[:imap_settings] = imap_settings
    h
  end

  def import_find_item(data)
    self.class.allow(:read, @cur_user).where(id: data[:id]).first
  end
end
