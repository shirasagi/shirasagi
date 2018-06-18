module Webmail::AccountExport
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    attr_accessor :in_file
    permit_params :in_file
  end

  def export_csv(items)
    csv = CSV.generate do |data|
      data << export_field_names
      items.each do |item|
        item.imap_settings.each_with_index do |setting, i|
          line = []
          line << item.id
          line << item.uid
          line << item.organization_uid
          line << i + 1
          account_fields.each { |k| line << setting.send(k) }
          data << line
        end
      end
    end
    csv.encode("SJIS", invalid: :replace, undef: :replace)
  end

  def export_template_csv(items)
    csv = CSV.generate do |data|
      data << export_field_names
      items.each do |item|
        line = []
        line << item.id
        line << item.uid
        line << item.organization_uid
        line << 1
        data << line
      end
    end
    csv.encode("SJIS", invalid: :replace, undef: :replace)
  end

  def import_csv
    validate_import_file
    return false unless errors.empty?

    CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8').each_with_index do |row, index|
      update_row(row, index)
    end
    errors.empty?
  end

  def update_row(row, index)
    id = row[t("id")].to_s.strip
    item = self.class.allow(:read, @cur_user).where(id: id).first

    if item.blank?
      item = self.class.new
      errors.add :base, "#{index + 1}: Could not find ##{data[:id]}"
      return item
    end

    if !item.allowed?(:edit, @cur_user)
      errors.add :base, "#{index + 1}: #{I18n.t('errors.messages.auth_error')}"
      return item
    end

    account_index    = row[t("account_index")].to_s.strip.to_i - 1
    name             = row[Webmail::ImapSetting.t("name")].to_s.strip
    from             = row[Webmail::ImapSetting.t("from")].to_s.strip
    address          = row[Webmail::ImapSetting.t("address")].to_s.strip
    imap_host        = row[Webmail::ImapSetting.t("imap_host")].to_s.strip
    imap_auth_type   = row[Webmail::ImapSetting.t("imap_auth_type")].to_s.strip
    imap_account     = row[Webmail::ImapSetting.t("imap_account")].to_s.strip
    in_imap_password = row[Webmail::ImapSetting.t("in_imap_password")].to_s.strip
    threshold_mb     = row[Webmail::ImapSetting.t("threshold_mb")].to_s.strip
    imap_sent_box    = row[Webmail::ImapSetting.t("imap_sent_box")].to_s.strip
    imap_draft_box   = row[Webmail::ImapSetting.t("imap_draft_box")].to_s.strip
    imap_trash_box   = row[Webmail::ImapSetting.t("imap_trash_box")].to_s.strip

    old_password = item.imap_settings[account_index].imap_password rescue nil

    setting = Webmail::ImapSetting.new.replace(
      name: name,
      from: from,
      address: address,
      imap_host: imap_host,
      imap_auth_type: imap_auth_type,
      imap_account: imap_account,
      in_imap_password: in_imap_password,
      imap_password: old_password,
      threshold_mb: threshold_mb,
      imap_sent_box: imap_sent_box,
      imap_draft_box: imap_draft_box,
      imap_trash_box: imap_trash_box
    )

    if account_index >= 0 && setting.valid?
      imap_settings = item.imap_settings.to_a
      imap_settings[account_index] = setting
      imap_settings = imap_settings.compact
      item.imap_settings = imap_settings

      item.cur_user = @cur_user
      item.cur_site = @cur_site if @cur_site
      item.save
    else
      errors.add :base, "#{index + 1}: #{I18n.t("errors.messages.imap_setting_validation_error")}"
    end

    item
  end

  private

  def account_fields
    %w(
      name from address imap_host imap_auth_type imap_account in_imap_password
      threshold_mb imap_sent_box imap_draft_box imap_trash_box
    )
  end

  def export_fields
    %w(id uid organization_uid account_index) + account_fields
  end

  def export_field_names
    %w(id uid organization_uid account_index).map { |k| t(k) } + account_fields.map { |k| Webmail::ImapSetting.t(k) }
  end

  def validate_import_file
    return errors.add :in_file, :blank if in_file.blank?

    fname = in_file.original_filename
    return errors.add :in_file, :invalid_file_type if ::File.extname(fname) !~ /^\.csv$/i

    begin
      headers = CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8').headers
      errors.add :in_file, :invalid_file_type if (export_field_names - headers).present?
      in_file.rewind
    rescue => e
      errors.add :in_file, :invalid_file_type
    end
  end
end
