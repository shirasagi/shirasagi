class Gws::Discussion::Topic
  include Gws::Referenceable
  include Gws::Discussion::Postable
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  #include Gws::Addon::Discussion::Release
  #include Gws::Addon::Discussion::ReadableSetting
  include Gws::Addon::Discussion::GroupPermission
  include Gws::Addon::History

  validates :text, presence: true

  #def updated?
  #  created.to_i != updated.to_i || created.to_i != descendants_updated.to_i
  #end
end
