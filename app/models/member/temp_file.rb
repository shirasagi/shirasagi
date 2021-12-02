class Member::TempFile
  include SS::Model::File
  include SS::Relation::Thumb
  include Cms::Reference::Member
  include Cms::MemberPermission

  default_scope ->{ where(model: "member/temp_file") }

  def previewable?(site: nil, user: nil, member: nil)
    return true if super

    member && member.id == self.member_id
  end
end
