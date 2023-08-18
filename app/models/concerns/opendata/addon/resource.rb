module Opendata::Addon::Resource
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    embeds_many :resources, class_name: "Opendata::Resource", order: :order.asc
    before_destroy :destroy_resources
  end

  def destroy_resources
    resources.destroy
  end
end
