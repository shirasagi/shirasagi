module Webmail::Address::OutlookExport
  extend ActiveSupport::Concern
  extend SS::Translation

  private

  def outlook_export_fields
    SS.config.webmail_address_export.export_fields["outlook"].keys.map(&:to_s)
  end

  def outlook_export_field_names
    SS.config.webmail_address_export.export_fields["outlook"].values
  end

  def outlook_import_required_fields
    names = []
    names << outlook_export_field_names[outlook_export_fields.index("family_name")]
    names << outlook_export_field_names[outlook_export_fields.index("given_name")]
    names << outlook_export_field_names[outlook_export_fields.index("email")]
    names
  end

  def outlook_import_convert_data(data)
    family_name = data.delete(:family_name)
    middle_name = data.delete(:middle_name)
    given_name  = data.delete(:given_name)

    family_kana = data.delete(:family_kana)
    middle_kana = data.delete(:middle_kana)
    given_kana  = data.delete(:given_kana)

    data[:name] = [family_name, middle_name, given_name].compact.join(" ")
    data[:kana] = [family_kana, middle_kana, given_kana].compact.join(" ")
    data
  end

  def outlook_import_find_item(data)
    nil
  end
end
