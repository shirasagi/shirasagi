class Gws::Facility
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::GroupPermission

  seqid :id
  field :name, type: String

  permit_params :name

  validates :name, presence: true
end
