class Member::PhotoFile
  include SS::Model::File
  include Cms::Reference::Member
  include Cms::MemberPermission
  include Cms::Lgwan::File

  default_thumb_size [360, 360]
  add_thumb_size :detail, [800, 600]

  default_scope ->{ where(model: "member/photo") }
end
