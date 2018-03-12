module Gws::Addon::Portal::Portlet
  module Report
    extend ActiveSupport::Concern
    extend SS::Addon

    set_addon_type :gws_portlet

    def find_report_items(portal, user)
      search = OpenStruct.new(
        cur_site: portal.site,
        cur_user: user,
        state: 'inbox'
      )

      Gws::Report::File.site(portal.site).
        without_deleted.
        search(search).
        order_by(updated: -1, id: -1).
        page(1).
        per(limit)
    end
  end
end
