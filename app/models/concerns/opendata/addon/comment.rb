module Opendata::Addon::Comment
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    has_many :comments, class_name: "Opendata::IdeaComment", dependent: :destroy, inverse_of: :idea
  end

end
