class Gws::Affair2::Overtime::File
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Affair2::OvertimeRecord
  include Gws::Addon::Affair2::Approver
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
end
