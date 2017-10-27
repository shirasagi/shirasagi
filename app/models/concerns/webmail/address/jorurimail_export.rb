module Webmail::Address::JorurimailExport
  extend ActiveSupport::Concern
  extend SS::Translation

  private

  def jorurimail_export_fields
    SS.config.webmail_address_export.export_fields["jorurimail"].keys.map(&:to_s)
  end

  def jorurimail_export_field_names
    SS.config.webmail_address_export.export_fields["jorurimail"].values
  end

  def jorurimail_import_required_fields
    names = []
    names << jorurimail_export_field_names[jorurimail_export_fields.index("name")]
    names << jorurimail_export_field_names[jorurimail_export_fields.index("email")]
    names
  end

  def jorurimail_import_convert_data(data)
    data
  end

  def jorurimail_import_find_item(data)
    nil
  end
end
