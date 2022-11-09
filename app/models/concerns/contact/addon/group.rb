module Contact::Addon::Group
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_many :contact_groups, class_name: "SS::Contact"
    field :contact_group_name, type: String
    field :contact_tel, type: String
    field :contact_fax, type: String
    field :contact_email, type: String
    field :contact_link_url, type: String
    field :contact_link_name, type: String

    permit_params contact_groups: %i[contact_group_name contact_tel contact_fax contact_email contact_link_url contact_link_name]

    before_validation :sync_with_main_contact
  end

  private

  def sync_with_main_contact
    main_contact = contact_groups.where(main_state: 'main').first
    if main_contact
      self.contact_group_name = main_contact.contact_group_name
      self.contact_tel = main_contact.contact_tel
      self.contact_fax = main_contact.contact_fax
      self.contact_email = main_contact.contact_email
      self.contact_link_url = main_contact.contact_link_url
      self.contact_link_name = main_contact.contact_link_name
    else
      self.contact_group_name = nil
      self.contact_tel = nil
      self.contact_fax = nil
      self.contact_email = nil
      self.contact_link_url = nil
      self.contact_link_name = nil
    end
  end
end
