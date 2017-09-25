class Gws::Facility::CustomField
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Reference::Facility::Item
  include Gws::Addon::Facility::InputSetting

  field :name, type: String
  field :order, type: Integer, default: 0
  field :tooltips, type: SS::Extensions::Lines

  permit_params :name, :order, :tooltips
end
