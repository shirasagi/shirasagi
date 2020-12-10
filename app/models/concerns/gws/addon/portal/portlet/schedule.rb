module Gws::Addon::Portal::Portlet
  module Schedule
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :schedule_member_mode, type: String
      embeds_ids :schedule_members, class_name: "Gws::User"
      permit_params :schedule_member_mode, schedule_member_ids: []
    end

    def schedule_member_mode_options
      %w(default specific).map do |v|
        [ I18n.t("gws/schedule.options.member_mode.#{v}"), v ]
      end
    end

    def schedule_member_mode_default?
      schedule_member_mode.blank? || schedule_member_mode == "default"
    end

    def schedule_member_mode_specific?
      !schedule_member_mode_default?
    end

    def find_schedule_members(portal)
      if schedule_member_mode_specific?
        # specific users
        return schedule_members.active.order_by_title(portal.site).compact
      end

      if portal.try(:portal_user).present?
        [ portal.portal_user ]
      elsif portal.try(:portal_group).present?
        portal.portal_group.users.active.order_by_title(portal.site).compact
      else
        []
      end
    end
  end
end
