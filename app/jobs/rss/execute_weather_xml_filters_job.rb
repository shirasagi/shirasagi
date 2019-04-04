class Rss::ExecuteWeatherXmlFiltersJob < Cms::ApplicationJob

  queue_as :default

  def put_log(message)
    Rails.logger.info(message)
  end

  def perform(page_ids)
    page_ids.each do |page_id|
      page = Rss::WeatherXmlPage.with_repl_master.find(page_id)
      put_log(page.name)

      context = OpenStruct.new(site: site, user: user, node: node)
      node.execute_weather_xml_filter(page, context)
    end
  end
end
