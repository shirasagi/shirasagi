module Contact::Addon
  module Group
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :contact_tel, type: String
      field :contact_fax, type: String
      field :contact_email, type: String
      field :contact_link_url, type: String
      field :contact_link_name, type: String
      permit_params :contact_tel, :contact_fax, :contact_email
      permit_params :contact_link_url, :contact_link_name
    end
  end
end
