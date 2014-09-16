# coding: utf-8
class Cms::Layout
  extend ActiveSupport::Autoload
  autoload :Model

  include Model

  index({ site_id: 1, filename: 1 }, { unique: true })
end
