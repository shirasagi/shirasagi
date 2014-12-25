class Cms::Layout
  extend ActiveSupport::Autoload
  include Model

  index({ site_id: 1, filename: 1 }, { unique: true })
end
