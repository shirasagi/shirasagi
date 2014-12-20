class Ezine::PublicEntry
  include Mongoid::Document

  store_in session: :public, collection: :ezine_entries

  field :email,              type: String
  field :email_type,         type: String
  field :entry_type,         type: String
  field :verification_token, type: String

  belongs_to :node, class_name: "Cms::Node"
end
