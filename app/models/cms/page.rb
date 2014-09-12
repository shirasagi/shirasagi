# coding: utf-8
class Cms::Page
  extend ActiveSupport::Autoload
  autoload :Feature
  autoload :Model

  include Model
  include Cms::Addon::Meta
  include Cms::Addon::Body
  include Cms::Addon::File
  include Cms::Addon::Release
  include Cms::Addon::RelatedPage
  include Category::Addon::Category
  include Event::Addon::Date
  include Workflow::Addon::Approver

  #default_scope ->{ where(route: "cms/page") }
end
