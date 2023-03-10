module Contact
  module_function

  def find_contact(cur_site, item)
    return unless item.respond_to?(:contact_group_relation)

    group = Cms::Group.all.site(cur_site).active.where(id: item.contact_group_id).first
    return unless group

    return [ group ] unless item.contact_group_related?

    if item.contact_group_contact_id.present?
      contact = group.contact_groups.where(id: item.contact_group_contact_id).first
    end
    contact ||= group.contact_groups.where(main_state: "main").first
    [ group, contact ]
  end
end
