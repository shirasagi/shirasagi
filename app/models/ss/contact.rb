class SS::Contact
  include SS::Document
  include SS::Liquidization

  embedded_in :group, class_name: "SS::Group"

  field :name, type: String
  field :contact_group_name, type: String
  field :contact_charge, type: String
  field :contact_tel, type: String
  field :contact_fax, type: String
  field :contact_email, type: String
  field :contact_postal_code, type: String
  field :contact_address, type: String
  field :contact_link_url, type: String
  field :contact_link_name, type: String
  field :main_state, type: String

  validates :name, presence: true, uniqueness: true
  validates :contact_link_url, "sys/trusted_url" => true, if: ->{ Sys::TrustedUrlValidator.url_restricted? }
  validates :main_state, inclusion: { in: %w(main), allow_blank: true }

  permit_params :name, :contact_group_name, :contact_charge, :contact_tel, :contact_fax, :contact_email
  permit_params :contact_postal_code, :contact_address, :contact_link_url, :contact_link_name, :main_state

  liquidize do
    export :name
    export :contact_group_name
    export :contact_charge
    export :contact_tel
    export :contact_fax
    export :contact_email
    export :contact_postal_code
    export :contact_address
    export :contact_link_url
    export :contact_link_name
    export :main_state
  end

  def same_contact?(dist)
    dist.deep_stringify_keys!
    return false if dist.blank?
    return false if all_empty?

    %w(
      contact_group_name contact_charge contact_tel contact_fax contact_email contact_postal_code contact_address
      contact_link_url contact_link_name
    ).each do |key|
      src_value = send(key).to_s.squish
      dist_value = dist[key].to_s.squish
      return false if src_value != dist_value
    end
    true
  end

  def all_empty?
    return false if name.present?
    return false if contact_group_name.present?
    return false if contact_charge.present?
    return false if contact_tel.present?
    return false if contact_fax.present?
    return false if contact_email.present?
    return false if contact_postal_code.present?
    return false if contact_address.present?
    return false if contact_link_url.present?
    return false if contact_link_name.present?
    true
  end
end
