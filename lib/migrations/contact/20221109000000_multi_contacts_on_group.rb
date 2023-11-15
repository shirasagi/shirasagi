class SS::Migration20221109000000
  include SS::Migration::Base

  depends_on "20220928000000"

  CONTACT_ATTRIBUTES = %i[
    contact_group_name contact_charge contact_tel contact_fax contact_email contact_link_url contact_link_name
  ].freeze

  def change
    each_group do |group|
      main_contact = SS::Contact.new
      CONTACT_ATTRIBUTES.each do |attr|
        main_contact.send("#{attr}=", trim(group.send(attr)))
      end
      main_contact.main_state = "main"
      main_contact.name = group.section_name

      group.contact_groups = [ main_contact ]
      unless group.save
        puts group.errors.full_messages.join("\n")
      end
    end
  end

  private

  def trim(text)
    return text if text.blank?
    text.strip.presence
  end

  def each_group
    all_group_ids = Cms::Group.all.pluck(:id)
    all_group_ids.each_slice(20) do |ids|
      Cms::Group.all.in(id: ids).to_a.each do |group|
        next if group.contact_groups.present?
        next if CONTACT_ATTRIBUTES.all? { |attr| group.send(attr).blank? }

        yield group
      end
    end
  end
end
