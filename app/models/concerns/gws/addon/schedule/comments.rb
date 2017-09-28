module Gws::Addon::Schedule::Comments
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :comments, class_name: 'Gws::Schedule::Comment', dependent: :destroy
  end
end
