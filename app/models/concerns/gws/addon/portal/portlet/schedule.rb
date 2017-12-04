module Gws::Addon::Portal::Portlet
  module Schedule
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      embeds_ids :schedule_members, class_name: "Gws::User"
      permit_params schedule_member_ids: []
    end

    def find_schedule_members(portal)
      if schedule_members.present?
        schedule_members.active.order_by_title(portal.site).compact
      elsif portal.try(:portal_user).present?
        [portal.portal_user]
      elsif portal.try(:portal_group).present?
        portal.portal_group.users.active.order_by_title(portal.site).compact
      else
        []
      end
    end
  end
end
