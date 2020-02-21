module Gws::Addon::Schedule::Todo::CommentPost
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :comments, class_name: 'Gws::Schedule::TodoComment', dependent: :destroy, validate: false
  end
end
