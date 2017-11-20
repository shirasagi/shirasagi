class Gws::Circular::Comment
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::GroupPermission

  seqid :id
  field :name, type: String
  field :text, type: String

  permit_params :name, :text

  belongs_to :post, class_name: 'Gws::Circular::Post', inverse_of: :comments
  validates :post_id, presence: true

  before_save -> {
  }
end
