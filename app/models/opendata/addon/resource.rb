# coding: utf-8
module Opendata::Addon::Resource
  extend SS::Addon
  extend ActiveSupport::Concern

  set_order 200

  included do
    embeds_many :resources, class_name: "Opendata::Resource"
  end
end
