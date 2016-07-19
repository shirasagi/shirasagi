FactoryGirl.define do
  factory :rss_node_page, class: Rss::Node::Page, traits: [:cms_node] do
    route "rss/page"
    rss_url { "http://example.com/#{filename}" }
    rss_max_docs 20
    rss_refresh_method { Rss::Node::Page::RSS_REFRESH_METHOD_AUTO }
  end

  factory :rss_node_weather_xml, class: Rss::Node::WeatherXml, traits: [:cms_node] do
    route "rss/weather_xml"
    rss_max_docs 20
    page_state 'closed'
  end
end
