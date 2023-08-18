class Member::GroupMember
  extend SS::Translation
  include SS::Document

  embedded_in :group, class_name: "Member::Group"
  belongs_to :member, class_name: "Cms::Member"
  field :state, type: String
  permit_params :member_id, :state
  validates :member_id, presence: true, :uniqueness => true
  validates :state, presence: true, inclusion: { in: %w(admin user inviting disabled rejected) }

  def state_options
    %w(admin user inviting disabled rejected).map do |v|
      [I18n.t("member.options.group_member_state.#{v}"), v]
    end
  end
end
