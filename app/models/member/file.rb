class Member::File
  include SS::Model::File
  include Cms::Reference::Member
  include Cms::MemberPermission
  include Cms::Lgwan::File

  default_scope ->{ where(model: /^member\//) }

  def previewable?(site: nil, user: nil, member: nil)
    return true if super

    return false if !member
    return false if !site || !site.is_a?(SS::Model::Site) || self.site_id != site.id

    member.id == self.member_id
  end
end
