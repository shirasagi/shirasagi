class Chat::LineBot::RecordPhrase
  include SS::Document
  include SS::Reference::Site
  include Cms::Reference::Node
  include Cms::SitePermission

  field :name, type: String
  field :frequency, type: Integer, default: 0

  validates :name, uniqueness: true
end