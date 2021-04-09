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
      %w(default current_user under_current_group specific).map do |v|
        [ I18n.t("gws/schedule.options.member_mode.#{v}"), v ]
      end
    end

    def schedule_member_mode_default?
      schedule_member_mode.blank? || schedule_member_mode == "default"
    end

    def schedule_member_mode_current_user?
      schedule_member_mode == "current_user"
    end

    def schedule_member_mode_under_current_group?
      schedule_member_mode == "under_current_group"
    end

    def schedule_member_mode_specific?
      schedule_member_mode == "specific"
    end

    def find_schedule_members(portal)
      if schedule_member_mode_specific?
        # specific users
        return schedule_members.active.order_by_title(portal.site).compact
      end

      if schedule_member_mode_current_user?
        return portal.cur_user ? [ portal.cur_user ] : []
      end

      if schedule_member_mode_under_current_group?
        return portal.cur_group ? Gws::User.site(portal.cur_group).active.order_by_title(portal.site).compact : []
      end

      # schedule_member_mode_default?
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
