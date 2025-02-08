require_relative '../../../config/initializers/img_settings'

class Member::PhotoFile
  include SS::Model::File
  include Cms::Reference::Member
  include Cms::MemberPermission
  include Cms::Lgwan::File

  DEFAULT_THUMB_SIZE = ImgSettings::DEFAULT_THUMB_SIZE
  THUMB_SIZE_DETAIL = ImgSettings::THUMB_SIZES

  default_thumb_size DEFAULT_THUMB_SIZE
  add_thumb_size :detail, THUMB_SIZE_DETAIL

  default_scope ->{ where(model: "member/photo") }
end
