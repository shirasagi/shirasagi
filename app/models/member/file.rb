class Member::File
  include SS::Model::File
  include SS::Relation::Thumb
  include Cms::Reference::Member
  include Cms::MemberPermission

  default_scope ->{ where(model: /^member\//) }

  def previewable?(opts = {})
    cur_user   = opts[:user]
    cur_member = opts[:member]

    return true if cur_user
    return false unless cur_member
    return false unless member
    return cur_member.id == member.id
  end
end
