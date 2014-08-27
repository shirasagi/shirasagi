# coding: utf-8
class Cms::Page
  extend ActiveSupport::Autoload
  autoload :Feature
  autoload :Model

  include Model

  #default_scope ->{ where(route: "cms/page") }
end