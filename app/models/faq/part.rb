module Faq::Part
  class Search
    include Cms::Part::Model
    include Faq::Addon::Search

    default_scope ->{ where(route: "faq/search") }
  end
end
