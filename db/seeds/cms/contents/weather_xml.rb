puts "# weather_xml"

puts Jmaxml::QuakeRegion.model_name.human
Jmaxml::QuakeRegionImportJob.import_from_zip("weather_xml_regions/quake_regions.zip", site_id: @site)

puts Jmaxml::TsunamiRegion.model_name.human
Jmaxml::TsunamiRegionImportJob.import_from_zip("weather_xml_regions/tsunami_regions.zip", site_id: @site)

puts Jmaxml::ForecastRegion.model_name.human
Jmaxml::ForecastRegionImportJob.import_from_zip("weather_xml_regions/forecaset_regions.zip", site_id: @site)

puts Jmaxml::WaterLevelStation.model_name.human
Jmaxml::WaterLevelStationImportJob.import_from_zip("weather_xml_regions/water_level_stations.zip", site_id: @site)

weather_xml_node = save_node route: "rss/weather_xml", filename: "weather",
                             name: "気象庁防災XML", layout_id: @layouts["one"].id, rss_max_docs: 100, page_state: "closed",
                             earthquake_intensity: "5+", anpi_mail_id: @ezine_anpi.try(:id), my_anpi_post_id: @anpi_node.try(:id),
                             target_region_ids: %w(350 351 352).map { |code| Jmaxml::QuakeRegion.site(@site).find_by(code: code).id }

trigger1 = Jmaxml::Trigger::QuakeIntensityFlash.site(@site).where(name: '震度5強').first_or_create(
  earthquake_intensity: '5+',
  target_region_ids: Jmaxml::QuakeRegion.site(@site).where(name: /東京/).pluck(:id).sort)

action1 = Jmaxml::Action::PublishPage.site(@site).where(name: '記事ページ作成').first_or_create(
  publish_to_id: Cms::Node.site(@site).find_by(filename: 'docs').id, publish_state: 'draft',
  category_ids: %w(shisei/soshiki/kikikanri kurashi/bosai/jyoho).map { |f| Cms::Node.site(@site).find_by(filename: f).id })
action2 = Jmaxml::Action::SendMail.site(@site).where(name: 'メール送信').first_or_create(
  sender_email: 'admin@example.jp', signature_text: "----\r\nシラサギ市危機管理部",
  recipient_user_ids: Cms::User.site(@site).pluck(:id))
action3 = Jmaxml::Action::SwitchUrgency.site(@site).where(name: '緊急災害：トップページ').first_or_create(
  urgency_layout_id: Cms::Layout.site(@site).find_by(filename: 'urgency-layout/top-level3.layout.html').id)

weather_xml_node.filters.where(name: '震度5強の地震発生').first_or_create(
  trigger_ids: [trigger1.id.to_s], action_ids: [action1.id.to_s, action2.id.to_s, action3.id.to_s])
