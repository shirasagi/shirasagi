module Member::Addon
  module MemberInvitationSetting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :member_invitation_subject, type: String
      field :member_invitation_template, type: String
      field :member_invitation_signature, type: String
      field :member_joins_to_invited_group, type: String
      permit_params :member_invitation_subject
      permit_params :member_invitation_template
      permit_params :member_invitation_signature
      permit_params :member_joins_to_invited_group
      validates :member_joins_to_invited_group, inclusion: { in: %w(manual auto), allow_blank: true }
    end

    def member_joins_to_invited_group_options
      %w(manual auto).map { |m| [ I18n.t("member.options.member_joins_to_invited_group.#{m}"), m ] }.to_a
    end
  end
end
