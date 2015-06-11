class Cms::Layout
  include Cms::Model::Layout

  index({ site_id: 1, filename: 1 }, { unique: true })
end
