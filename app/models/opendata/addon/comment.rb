module Opendata::Addon::Comment
  extend SS::Addon
  extend ActiveSupport::Concern

  set_order 204

  included do
    embeds_many :comments, class_name: "Opendata::Comment"
    before_destroy :destroy_comments
  end

  def destroy_comments
    comments.destroy
  end
end
