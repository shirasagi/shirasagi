module Contact::Addon::Page
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :contact_state, type: String
    field :contact_charge, type: String
    field :contact_tel, type: String
    field :contact_fax, type: String
    field :contact_email, type: String
    field :contact_link_url, type: String
    field :contact_link_name, type: String
    belongs_to :contact_group, class_name: "Cms::Group"
    belongs_to :contact_group_contact, class_name: "SS::Contact"
    field :contact_group_relation, type: String

    before_validation :update_contacts

    validates :contact_state, inclusion: { in: %w(show hide), allow_blank: true }
    validates :contact_link_url, "sys/trusted_url" => true, if: ->{ Sys::TrustedUrlValidator.url_restricted? }
    validates :contact_group_relation, inclusion: { in: %w(related unrelated), allow_blank: true }

    permit_params :contact_state, :contact_group_id, :contact_charge
    permit_params :contact_tel, :contact_fax, :contact_email
    permit_params :contact_link_url, :contact_link_name
    permit_params :contact_group_contact_id, :contact_group_relation

    if respond_to? :liquidize
      liquidize do
        export :contact_state
        export :contact_charge
        export :contact_tel
        export :contact_fax
        export :contact_email
        export :contact_link_url
        export :contact_link_name
        export as: :contact_group do
          contact_group.present? && contact_group.active? ? contact_group : nil
        end
      end
    end

    if respond_to? :after_chorg
      before_chorg :remove_contact_attributes_to_update
      after_chorg :update_contacts
    end
  end

  def contact_state_options
    %w(show hide).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def contact_group_relation_options
    %w(related unrelated).map do |v|
      [
        I18n.t("contact.options.relation.#{v}.title"),
        v,
        "data-description" => I18n.t("contact.options.relation.#{v}.description", default: nil)
      ]
    end
  end

  def contact_group_related?
    contact_group_relation.blank? || contact_group_relation == "related"
  end

  def show_contact?
    (contact_state != "hide") && contact_present?
  end

  def contact_present?
    %i[
      contact_charge
      contact_tel
      contact_fax
      contact_email
      contact_link_url
      contact_link_name
      contact_group
    ].any? { |m| send(m).present? }
  end

  private

  CONTACT_ATTRIBUTES = %w[
    contact_charge contact_tel contact_fax contact_email contact_link_url contact_link_name
  ].freeze

  def remove_contact_attributes_to_update
    hash = Chorg.current_context.updating_attributes
    CONTACT_ATTRIBUTES.each do |attr|
      if hash.key?(attr)
        hash.delete(attr)
      end
    end
    Chorg.current_context.updating_attributes = hash
  end

  def update_contacts
    return unless contact_group
    return unless contact_group_contact_id

    chorg_options = Chorg.current_context.try(:options)
    force_overwrite = chorg_options.present? && chorg_options['forced_overwrite']
    return if !force_overwrite && !contact_group_related?

    contact = contact_group.contact_groups.where(id: contact_group_contact_id).first
    if contact.blank?
      self.contact_group_contact_id = nil
      return
    end

    self.contact_charge = contact.contact_group_name
    self.contact_tel = contact.contact_tel
    self.contact_fax = contact.contact_fax
    self.contact_email = contact.contact_email
    self.contact_link_url = contact.contact_link_url
    self.contact_link_name = contact.contact_link_name
  end
end
