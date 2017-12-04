class Gws::Memo::Message
  include ActiveSupport::NumberHelper
  include SS::Document
  include Gws::Model::Memo::Message
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission
  include Gws::Addon::Member
  include Webmail::Addon::MailBody
  include Gws::Addon::File
  include Gws::Addon::Memo::Comments
end
