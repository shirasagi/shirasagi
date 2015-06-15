module Opendata::Addon::UrlResource
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    embeds_many :url_resources, class_name: "Opendata::UrlResource"
    before_destroy :destroy_url_resources
  end

  def destroy_url_resources
    url_resources.destroy
  end
end

