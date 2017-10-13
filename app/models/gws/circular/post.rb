class Gws::Circular::Post
  include Gws::Referenceable
  include Gws::Board::Postable
  include SS::Addon::Markdown

  store_in collection: 'gws_circular_posts'
  set_permission_name 'gws_circular_posts'

  belongs_to :topic, class_name: 'Gws::Circular::Topic', inverse_of: :descendants
  belongs_to :parent, class_name: 'Gws::Circular::Topic', inverse_of: :children
  before_validation ->{ topic.marked_by(user) }, if: -> { topic.mark_type == 'normal' && topic.markable?(user) }
end
