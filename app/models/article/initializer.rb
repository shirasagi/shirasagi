module Article
  class Initializer
    Cms::Node.plugin "article/page"
    Cms::Node.plugin "article/search"
    Cms::Node.plugin 'article/map_search'
    Cms::Node.plugin "article/form_export"
    Cms::Part.plugin "article/page"
    Cms::Part.plugin "article/page_navi"
    Cms::Part.plugin "article/search"

    Cms::Role.permission :read_other_article_pages
    Cms::Role.permission :read_private_article_pages
    Cms::Role.permission :edit_other_article_pages
    Cms::Role.permission :edit_private_article_pages
    Cms::Role.permission :delete_other_article_pages
    Cms::Role.permission :delete_private_article_pages
    Cms::Role.permission :release_other_article_pages
    Cms::Role.permission :release_private_article_pages
    Cms::Role.permission :close_other_article_pages
    Cms::Role.permission :close_private_article_pages
    Cms::Role.permission :approve_other_article_pages
    Cms::Role.permission :approve_private_article_pages
    Cms::Role.permission :reroute_other_article_pages
    Cms::Role.permission :reroute_private_article_pages
    Cms::Role.permission :revoke_other_article_pages
    Cms::Role.permission :revoke_private_article_pages
    Cms::Role.permission :move_private_article_pages
    Cms::Role.permission :move_other_article_pages
    Cms::Role.permission :import_private_article_pages
    Cms::Role.permission :import_other_article_pages
    Cms::Role.permission :unlock_other_article_pages

    SS::File.model "article/page", SS::File
  end
end
