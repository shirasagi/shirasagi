module Faq::Part
  class Search
    include Cms::Model::Part
    include Cms::Addon::Release
    include Faq::Addon::Search
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "faq/search") }
  end
end
