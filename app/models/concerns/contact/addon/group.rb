module Contact::Addon::Group
  extend ActiveSupport::Concern
  extend SS::Addon

  MAX_CONTACT_COUNT = 20

  included do
    embeds_many :contact_groups, class_name: "SS::Contact"
    field :contact_group_name, type: String
    field :contact_tel, type: String
    field :contact_fax, type: String
    field :contact_email, type: String
    field :contact_link_url, type: String
    field :contact_link_name, type: String

    permit_params contact_groups: %i[_id contact_group_name contact_tel contact_fax contact_email
                                     contact_link_url contact_link_name main_state]

    before_validation :sync_with_main_contact
    before_validation :remove_empty_contact_groups
    validates :contact_groups, length: { maximum: MAX_CONTACT_COUNT }
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

  def remove_empty_contact_groups
    to_be_removed = []
    contact_groups.each do |contact_group|
      if contact_group.changed? && contact_group.all_empty?
        to_be_removed << contact_group.id
      end
    end
    return if to_be_removed.blank?

    contact_groups = self.contact_groups.dup
    to_be_removed.each do |id|
      contact_groups.delete_if { |contact_group| contact_group.id == id }
    end
    self.contact_groups = contact_groups
  end
end
