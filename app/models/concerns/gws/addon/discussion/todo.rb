module Gws::Addon::Discussion::Todo
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    belongs_to :discussion_forum, class_name: "Gws::Discussion::Forum"

    scope :discussion_forum, ->(discussion_forum) { where(discussion_forum_id: discussion_forum.id) }
  end
end
