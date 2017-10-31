module Webmail::AddressExport
  extend ActiveSupport::Concern
  extend SS::Translation
  include Gws::Export
  include Webmail::Address::WebmailExport
  include Webmail::Address::JorurimailExport
  include Webmail::Address::OutlookExport

  included do
    attr_accessor :import_format
    permit_params :import_format
  end

  def validate_import_file
    super
    return false unless errors.empty?

    headers = CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8').headers
    in_file.rewind

    case import_format
    when "jorurimail"
      required = jorurimail_import_required_fields - headers
    when "outlook"
      required = outlook_import_required_fields - headers
    else
      required = webmail_import_required_fields - headers
    end

    if required.size > 0
      self.errors.add :in_file, :invalid_file_type
      false
    else
      true
    end
  end

  def import_format_options
    SS.config.webmail_address_export.import_format.map { |k, v| [k, v] }
  end

  private

  def export_fields
    case import_format
    when "jorurimail"
      jorurimail_export_fields
    when "outlook"
      outlook_export_fields
    else
      webmail_export_fields
    end
  end

  def export_field_names
    case import_format
    when "jorurimail"
      jorurimail_export_field_names
    when "outlook"
      outlook_export_field_names
    else
      super
    end
  end

  def export_convert_item(item, data)
    webmail_export_convert_item(item, data)
  end

  def import_convert_data(data)
    case import_format
    when "jorurimail"
      jorurimail_import_convert_data(data)
    when "outlook"
      outlook_import_convert_data(data)
    else
      webmail_import_convert_data(data)
    end
  end

  def import_find_item(data)
    case import_format
    when "jorurimail"
      jorurimail_import_find_item(data)
    when "outlook"
      outlook_import_find_item(data)
    else
      webmail_import_find_item(data)
    end
  end
end
