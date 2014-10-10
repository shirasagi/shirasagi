module Faq
  class Initializer
    Cms::Node.plugin "faq/page"
    Cms::Node.plugin "faq/search"
    Cms::Part.plugin "faq/search"

    Cms::Role.permission :read_other_faq_pages
    Cms::Role.permission :read_private_faq_pages
    Cms::Role.permission :edit_other_faq_pages
    Cms::Role.permission :edit_private_faq_pages
    Cms::Role.permission :delete_other_faq_pages
    Cms::Role.permission :delete_private_faq_pages
  end
end
