class SS::Migration20200204000001
  include SS::Migration::Base

  depends_on "20200204000000"

  def change
    Gws::Portal::GroupSetting.all.set(portal_notice_state: "hide", portal_monitor_state: "hide", portal_link_state: "hide")
  end
end
