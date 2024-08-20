class Gws::Discussion::Bookmark
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site

  belongs_to :post, class_name: "Gws::Discussion::Post"
  belongs_to :forum, class_name: "Gws::Discussion::Forum"

  validates :post_id, presence: true
  validates :forum_id, presence: true

  default_scope ->{ order_by(updated: -1) }
end
