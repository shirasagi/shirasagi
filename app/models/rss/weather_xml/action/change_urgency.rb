class Rss::WeatherXml::Action::ChangeUrgency < Rss::WeatherXml::Action::Base
  belongs_to :urgency_layout, class_name: "Cms::Layout"
  permit_params :urgency_layout_id
end
