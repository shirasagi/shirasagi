class Cms::Layout
  include Cms::Model::Layout
  include Cms::Addon::LayoutHtml
  include Cms::Addon::LayoutPart
  include Cms::Addon::GroupPermission
  include Cms::Addon::LayoutSearch
  include History::Addon::Backup

  index({ site_id: 1, filename: 1 }, { unique: true })
end
