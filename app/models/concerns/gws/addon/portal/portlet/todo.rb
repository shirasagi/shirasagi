module Gws::Addon::Portal::Portlet
  module Todo
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :todo_state, type: String, default: 'unfinished'
      embeds_ids :todo_members, class_name: "Gws::User"
      permit_params :todo_state, todo_member_ids: []
    end

    def todo_state_options
      %w(unfinished finished both).map { |v| [I18n.t("gws/schedule/todo.options.todo_state.#{v}"), v] }
    end

    def find_todo_members(portal)
      if todo_members.present?
        todo_members.active.order_by_title(portal.site).compact
      elsif portal.try(:portal_user).present?
        [portal.portal_user]
      elsif portal.try(:portal_group).present?
        portal.portal_group.users.active.order_by_title(portal.site).compact
      else
        []
      end
    end

    def find_todo_items(portal, user)
      search = { site: portal.site, todo_state: todo_state.presence || 'unfinished' }

      Gws::Schedule::Todo.site(portal.site).
        member_or_readable(user, site: portal.site).
        without_deleted.
        search(search).
        order_by(end_at: 1).
        page(1).
        per(limit)
    end
  end
end
