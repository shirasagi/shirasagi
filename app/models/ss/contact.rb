class SS::Contact
  include SS::Document

  embedded_in :group, class_name: "SS::Group"

  field :contact_group_name, type: String
  field :contact_tel, type: String
  field :contact_fax, type: String
  field :contact_email, type: String
  field :contact_link_url, type: String
  field :contact_link_name, type: String
  field :main_state, type: String

  validates :contact_link_url, "sys/trusted_url" => true, if: ->{ Sys::TrustedUrlValidator.url_restricted? }
  validates :main_state, inclusion: { in: %w(main), allow_blank: true }

  permit_params :contact_group_name, :contact_tel, :contact_fax, :contact_email
  permit_params :contact_link_url, :contact_link_name, :main_state
end
