class Rss::ExecuteWeatherXmlFiltersJob < Cms::ApplicationJob
  def put_log(message)
    Rails.logger.info(message)
  end

  def perform(page_ids)
    weather_node = node.becomes_with_route
    page_ids.each do |page_id|
      page = Rss::WeatherXmlPage.with_repl_master.find(page_id)
      put_log(page.name)

      context = OpenStruct.new(site: site, user: user, node: weather_node)
      weather_node.execute_weather_xml_filter(page, context)
    end
  end
end
