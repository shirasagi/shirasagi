module Gws::Addon::Facility::ReservableMember
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    embeds_ids :reservable_members, class_name: "Gws::User"

    permit_params reservable_member_ids: []

    #validates :reservable_member_ids, presence: true
  end
end
