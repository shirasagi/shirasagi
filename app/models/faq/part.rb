module Faq::Part
  class Search
    include Cms::Model::Part
    include Faq::Addon::Search
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Multilingual::Addon::Part

    default_scope ->{ where(route: "faq/search") }
  end
end
