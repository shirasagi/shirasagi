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
      field :contact_link_url, type: String
      field :contact_link_name, type: String
      belongs_to :contact_group, class_name: "Cms::Group"

      validates :contact_state, inclusion: { in: %w(show hide), allow_blank: true }
      validates :contact_link_url, "sys/trusted_url" => true, if: ->{ Sys::TrustedUrlValidator.url_restricted? }

      permit_params :contact_state, :contact_group_id, :contact_charge
      permit_params :contact_tel, :contact_fax, :contact_email
      permit_params :contact_link_url, :contact_link_name

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
    end

    def contact_state_options
      %w(show hide).map do |v|
        [ I18n.t("ss.options.state.#{v}"), v ]
      end
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

    def contact_link
      contact_link_name || contact_link_url
    end
  end
end
