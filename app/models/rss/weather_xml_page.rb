class Rss::WeatherXmlPage
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include Rss::Addon::Page::Body
  include Rss::Addon::Page::WeatherXml
  include Category::Addon::Category
  include Cms::Addon::ParentCrumb
  include Cms::Addon::RelatedPage
  include Cms::Addon::Release
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  set_permission_name "article_pages"

  default_scope ->{ where(route: "rss/weather_xml_page") }
end
