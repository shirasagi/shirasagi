class Gws::Notice::Folder
  include SS::Document
  include Gws::Model::Folder
  include Gws::Addon::Notice::ResourceLimitation
  include Gws::Addon::Member
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
end
