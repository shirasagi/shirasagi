module Gws::Addon::Portal::Portlet
  module Todo
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :todo_state, type: String
      permit_params :todo_state
    end

    def todo_state_options
      Gws::Schedule::Todo.todo_state_filter_options
    end

    def find_todo_items(portal, user)
      search = { site: portal.site, todo_state: todo_state.presence || 'except_finished' }

      Gws::Schedule::Todo.site(portal.site).
        member(user).
        without_deleted.
        search(search).
        order_by(end_at: 1).
        page(1).
        per(limit)
    end
  end
end
