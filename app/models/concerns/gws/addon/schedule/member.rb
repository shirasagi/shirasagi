module Gws::Addon::Schedule::Member
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :members, class_name: "Gws::User"

    permit_params member_ids: []

    validates :member_ids, presence: true

    scope :member, ->(user) { where member_ids: user.id }
  end
end
