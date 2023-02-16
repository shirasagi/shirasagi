class SS::Migration20230213000000
  include SS::Migration::Base

  def change
    Gws::Portal::PresetSetting.each { |portal| change_portal(portal) }
    Gws::Portal::GroupSetting.each { |portal| change_portal(portal) }
    Gws::Portal::UserSetting.each { |portal| change_portal(portal) }

    Gws::Portal::PresetPortlet.each { |portlet| change_portlet(portlet) }
    Gws::Portal::GroupPortlet.each { |portlet| change_portlet(portlet) }
    Gws::Portal::UserPortlet.each { |portlet| change_portlet(portlet) }
  end

  def change_portal(portal)
    site = portal.site
    return if site.nil?

    if portal.portal_notice_browsed_state.blank?
      portal.set(portal_notice_browsed_state: site.notice_browsed_state)
    end
    if portal.portal_notice_severity.blank?
      portal.set(portal_notice_severity: site.notice_severity)
    end
  end

  def change_portlet(portlet)
    site = portlet.site
    return if site.nil?

    if portlet.notice_browsed_state.blank?
      portlet.set(notice_browsed_state: site.notice_browsed_state)
    end
    if portlet.notice_severity.blank?
      portlet.set(notice_severity: site.notice_severity)
    end
  end
end
