class Gws::Schedule::Facility
  include SS::Document
  include Gws::Addon::GroupPermission

  field :name, type: String

  permit_params :name

  validates :name, presence: true
end
