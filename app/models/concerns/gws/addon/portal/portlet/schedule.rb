module Gws::Addon::Portal::Portlet
  module Schedule
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      embeds_ids :schedule_members, class_name: "Gws::User"
      permit_params schedule_member_ids: []
    end

    def resolve_schedule_members(portal)
      if schedule_members.present?
        schedule_members.active.order_by_title(site).compact
      elsif portal.my_portal? || portal.user_portal?
        [portal.portal_user]
      else
        portal.portal_group.users.active.order_by_title(site).compact
      end
    end
  end
end
