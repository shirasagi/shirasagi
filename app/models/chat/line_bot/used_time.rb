class Chat::LineBot::UsedTime
  include SS::Document
  include SS::Reference::Site
  include Cms::Reference::Node
  include Cms::SitePermission

  field :hour, type: Integer
end