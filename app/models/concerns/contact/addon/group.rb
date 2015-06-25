module Contact::Addon
  module Group
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :contact_tel, type: String
      field :contact_fax, type: String
      field :contact_email, type: String
      permit_params :contact_tel, :contact_fax, :contact_email
    end
  end
end
