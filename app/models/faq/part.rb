module Faq::Part
  class Search
    include Cms::Model::Part
    include Faq::Addon::Search

    default_scope ->{ where(route: "faq/search") }
  end
end
