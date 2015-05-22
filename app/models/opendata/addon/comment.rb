module Opendata::Addon::Comment
  extend SS::Addon
  extend ActiveSupport::Concern

  set_order 204

  included do
    embeds_many :comments, class_name: "Opendata::IdeaComment"
  end

end
