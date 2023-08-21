class Member::BlogLayout
  include Cms::Model::Layout
  include Cms::Addon::Html
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  set_permission_name "member_blogs"

  index({ site_id: 1, filename: 1 }, { unique: true })
end
