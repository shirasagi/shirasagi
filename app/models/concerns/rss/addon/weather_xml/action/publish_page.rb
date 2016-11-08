module Rss::Addon::WeatherXml::Action::PublishPage
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_one :action_publish_page, class_name: "Rss::WeatherXml::Action::PublishPage"
    accepts_nested_attributes_for :action_publish_page
    permit_params action_publish_page: [ :node_id, :state ]
  end
end
