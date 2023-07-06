class SS::Migration20230224000001
  include SS::Migration::Base

  def change
    Gws::Portal::GroupPortlet.each { |portlet| change_portlet(portlet) }
    Gws::Portal::UserPortlet.each { |portlet| change_portlet(portlet) }
  end

  def change_portlet(portlet)
    site = portlet.site
    return if site.nil?

    if portlet.survey_answered_state.blank?
      portlet.set(survey_answered_state: site.survey_answered_state)
    end
    if portlet.survey_sort.blank?
      portlet.set(survey_sort: site.survey_sort)
    end
    if portlet.survey_sort == "due_date"
      portlet.set(survey_sort: "due_date_asc")
    end
    if portlet.survey_sort == "updated"
      portlet.set(survey_sort: "updated_asc")
    end
  end
end
