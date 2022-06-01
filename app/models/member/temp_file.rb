class Member::TempFile
  include SS::Model::File
  include Cms::Reference::Member
  include Cms::MemberPermission

  default_scope ->{ where(model: "member/temp_file") }

  def previewable?(site: nil, user: nil, member: nil)
    return true if super

    return false if !member
    return false if !site || !site.is_a?(SS::Model::Site) || self.site_id != site.id

    member.id == self.member_id
  end
end
