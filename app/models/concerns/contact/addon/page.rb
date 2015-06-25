module Contact::Addon
  module Page
    extend ActiveSupport::Concern
    extend SS::Addon

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
        [
          [I18n.t('views.options.state.show'), 'show'],
          [I18n.t('views.options.state.hide'), 'hide'],
        ]
      end

      def contact_present?
        [contact_charge,
         contact_tel,
         contact_fax,
         contact_email
        ].map(&:present?).any?
      end
  end
end
