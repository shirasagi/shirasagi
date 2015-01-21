module Contact::Addon
  module Page
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 400

    included do
      field :contact_state, type: String
      field :contact_charge, type: String
      field :contact_tel, type: String
      field :contact_fax, type: String
      field :contact_email, type: String
      belongs_to :contact_group, class_name: "SS::Group"
      permit_params :contact_state, :contact_group_id, :contact_charge
      permit_params :contact_tel, :contact_fax, :contact_email
    end

    public
      def contact_state_options
        [%w(表示 show), %w(非表示 hide)]
      end

      def contact_present?
        [contact_charge,
         contact_tel,
         contact_fax,
         contact_email
        ].map(&:present?).any?
      end
  end

  module Group
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 400

    included do
      field :contact_tel, type: String
      field :contact_fax, type: String
      field :contact_email, type: String
      permit_params :contact_tel, :contact_fax, :contact_email
    end
  end
end
