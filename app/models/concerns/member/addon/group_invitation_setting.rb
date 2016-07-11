module Member::Addon
  module GroupInvitationSetting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :group_invitation_subject, type: String
      field :group_invitation_template, type: String
      field :group_invitation_signature, type: String
      permit_params :group_invitation_subject
      permit_params :group_invitation_template
      permit_params :group_invitation_signature
    end
  end
end
