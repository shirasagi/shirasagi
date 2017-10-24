class Gws::Circular::Post
  include Gws::Referenceable
  include Gws::Board::Postable
  include SS::Addon::Markdown

  # override
  store_in collection: 'gws_circular_posts'
  set_permission_name 'gws_circular_topics'

  belongs_to :topic, class_name: 'Gws::Circular::Topic', inverse_of: :descendants
  belongs_to :parent, class_name: 'Gws::Circular::Topic', inverse_of: :children
  before_validation ->{ topic.mark_by(user).update }, if: -> { topic.markable?(user) }

  def allowed?(action, user, opts = {})
    self.topic.try(:member?, user) || super
  end
end
