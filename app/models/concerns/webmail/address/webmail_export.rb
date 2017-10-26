module Webmail::Address::WebmailExport
  extend ActiveSupport::Concern
  extend SS::Translation

  private

  def webmail_export_fields
    %w(
      id name kana company title tel email
      home_postal_code home_prefecture home_city home_street_address home_tel home_fax
      office_postal_code office_prefecture office_city office_street_address office_tel office_fax
      personal_webpage memo address_group_id
    )
  end

  def webmail_export_convert_item(item, data)
    i = webmail_export_fields.index("address_group_id")
    data[i] = item.address_group.name if item.address_group
    data
  end

  def webmail_import_convert_data(data)
    if data[:address_group_id].present?
      group = Webmail::AddressGroup.user(@cur_user).where(name: data[:address_group_id]).first
      data[:address_group_id] = group ? group.id : nil
    end
    data
  end

  def webmail_import_find_item(data)
    self.class.user(@cur_user).where(id: data[:id]).first
  end
end
