class Gws::Discussion::Base
  include Gws::Referenceable
  include Gws::Discussion::Postable
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Discussion::Release
  include Gws::Addon::ReadableSetting
  include Gws::Addon::Discussion::GroupPermission
  include Gws::Addon::History

  readable_setting_include_custom_groups
end
