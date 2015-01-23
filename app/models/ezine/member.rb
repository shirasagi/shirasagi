class Ezine::Member
  include SS::Document
  include SS::Reference::Site

  field :email, type: String, metadata: { from: :email }
  field :email_type, type: String

  belongs_to :node, class_name: "Cms::Node"

  validates :email, uniqueness: { scope: :node_id }, presence: true, email: true
end
