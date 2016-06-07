class Member::PhotoFile
  include SS::Model::File
  include SS::Relation::Thumb
  include Cms::Reference::Member
  include Cms::MemberPermission

  thumb_size [160, 120]
  add_thumb_size :detail, [800, 600]

  default_scope ->{ where(model: "member/photo") }
end
