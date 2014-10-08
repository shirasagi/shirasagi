# coding: utf-8
module Opendata::Addon::Resource
  extend SS::Addon
  extend ActiveSupport::Concern

  set_order 200

  included do
    embeds_many :resources, class_name: "Opendata::Resource"
    before_destroy :destroy_resources
  end

  def destroy_resources
    resources.destroy
  end
end
