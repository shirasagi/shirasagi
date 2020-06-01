class Chat::LineBot::Session
  include SS::Document
  include SS::Reference::Site
  include Cms::Reference::Node
  include Cms::SitePermission

  field :line_user_id, type: String
  field :date_created, type: String

  validates :line_user_id, uniqueness: { scope: :date_created }
end