module Gws::Addon::Notice::CommentPost
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :comments, class_name: 'Gws::Notice::Comment', dependent: :destroy
  end
end
