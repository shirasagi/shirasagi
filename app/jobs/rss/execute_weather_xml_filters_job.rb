class Rss::ExecuteWeatherXmlFiltersJob < Cms::ApplicationJob

  queue_as :default

  def put_log(message)
    Rails.logger.info(message)
  end

  def perform(page_ids)
    page_ids.each_slice(20) do |ids|
      Rss::WeatherXmlPage.with_repl_master.in(id: ids).reorder(id: 1).to_a.each do |page|
        put_log(page.name)

        context = OpenStruct.new(site: site, user: user, node: node)
        node.execute_weather_xml_filter(page, context)
      end
    end
  end
end
