class Member::File
  include SS::Model::File
  include SS::Relation::Thumb
  include Cms::Reference::Member
  include Cms::MemberPermission

  default_scope ->{ where(model: /^member\//) }

  def previewable?(opts = {})
    return true if super

    cur_member = opts[:member]
    cur_member && cur_member.id == member_id
  end
end
