# "Post" class for BBS. It represents "comment" models.
class Gws::Board::Post
  include Gws::Referenceable
  include Gws::Board::Postable
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Board::DescendantsFileInfo
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
end
