module Article
  class Initializer
    Cms::Node.plugin "article/page"
    Cms::Part.plugin "article/page"

    Cms::Role.permission :read_other_article_pages
    Cms::Role.permission :read_private_article_pages
    Cms::Role.permission :edit_other_article_pages
    Cms::Role.permission :edit_private_article_pages
    Cms::Role.permission :delete_other_article_pages
    Cms::Role.permission :delete_private_article_pages
  end
end
