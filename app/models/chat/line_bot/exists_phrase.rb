class Chat::LineBot::ExistsPhrase
  include SS::Document
  include SS::Reference::Site
  include Cms::Reference::Node
  include Cms::SitePermission

  field :name, type: String
  field :frequency, type: Integer, default: 0
  field :confirm_yes, type: Integer, default: 0
  field :confirm_no, type: Integer, default: 0
end