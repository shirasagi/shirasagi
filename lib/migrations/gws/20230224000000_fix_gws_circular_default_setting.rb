class SS::Migration20230224000000
  include SS::Migration::Base

  def change
    Gws::Portal::GroupPortlet.each { |portlet| change_portlet(portlet) }
    Gws::Portal::UserPortlet.each { |portlet| change_portlet(portlet) }
  end

  def change_portlet(portlet)
    site = portlet.site
    return if site.nil?

    if portlet.circular_article_state.blank?
      portlet.set(circular_article_state: site.circular_article_state)
    end
    if portlet.circular_sort.blank?
      portlet.set(circular_sort: site.circular_sort)
    end
  end
end
