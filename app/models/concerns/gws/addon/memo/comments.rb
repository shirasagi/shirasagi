module Gws::Addon::Memo::Comments
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :comments, class_name: 'Gws::Memo::Comment', dependent: :destroy
  end
end
