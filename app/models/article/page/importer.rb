class Article::Page::Importer
  include Cms::PageImportBase

  self.model = Article::Page
end
