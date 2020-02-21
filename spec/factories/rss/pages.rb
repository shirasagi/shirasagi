FactoryBot.define do
  factory :rss_page, class: Rss::Page, traits: [:cms_page] do
    transient do
      site nil
      node nil
    end

    cur_site { site || cms_site }
    filename { node ? "#{node.filename}/#{name}.html" : "dir/#{name}.html" }
    route "rss/page"
    rss_link { "http://example.com/#{filename}" }

    factory :rss_page_rss_link_blank do
      rss_link { "" }
    end
  end

  factory :rss_weather_xml_page, class: Rss::WeatherXmlPage, traits: [:cms_page] do
    route "rss/weather_xml_page"
    rss_link { "http://weather.example.com/developer/xml/data/#{SecureRandom.uuid}.xml" }
  end
end
