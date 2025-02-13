require_relative '../../../config/initializers/img_settings'

class Member::PhotoFile
  include SS::Model::File
  include Cms::Reference::Member
  include Cms::MemberPermission
  include Cms::Lgwan::File

  DEFAULT_THUMB_SIZE = ImgSettings::DEFAULT_THUMB_SIZE

  default_thumb_size DEFAULT_THUMB_SIZE
  add_thumb_size :detail, [800, 600]

  default_scope ->{ where(model: "member/photo") }
end
