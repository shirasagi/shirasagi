class Rss::WeatherXmlPage
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include Rss::Addon::Page::Body
  include Rss::Addon::Page::WeatherXml
  include Category::Addon::Category
  include Cms::Addon::Release
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  set_permission_name "article_pages"
  set_show_path "rss_weather_xml"

  store_in_repl_master
  default_scope ->{ where(route: "rss/weather_xml_page") }

  skip_callback(:destroy, :before, :create_history_trash)
end
