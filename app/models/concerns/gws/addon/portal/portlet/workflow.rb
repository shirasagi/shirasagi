module Gws::Addon::Portal::Portlet
  module Workflow
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    included do
      field :workflow_state, type: String
      permit_params :workflow_state
    end

    def workflow_state_options
      Gws::Workflow::File.new.workflow_state_options
    end

    def find_workflow_items(portal, user)
      search = OpenStruct.new(
        cur_site: portal.site,
        cur_user: user,
        state: workflow_state
      )

      Gws::Workflow::File.site(portal.site).
        without_deleted.
        search(search).
        page(1).
        per(limit)
    end
  end
end
