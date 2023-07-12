class Contact::UnifyJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "contact"

  def perform(*_args)
    criteria = Cms::Page.all.where(contact_group_id: group_item.id).in(contact_group_contact_id: sub_contacts.map(&:id))
    criteria.set(contact_group_contact_id: main_contact.id)

    criteria = Cms::Page.all.where(
      contact_group_id: group_item.id, contact_group_contact_id: main_contact.id, contact_group_relation: "related")
    criteria.set(
      contact_charge: main_contact.contact_group_name,
      contact_tel: main_contact.contact_tel, contact_fax: main_contact.contact_fax, contact_email: main_contact.contact_email,
      contact_link_url: main_contact.contact_link_url, contact_link_name: main_contact.contact_link_name)

    sub_contacts.each(&:destroy)

    Contact::PageCountJob.bind(site_id: site.id).perform_now
  end

  private

  def task_cond
    cond = { name: "#{self.class.task_name}:#{group_item.id}" }
    cond[:site_id] = site_id
    cond
  end

  def group_item
    @group_item ||= Cms::Group.find(arguments[0])
  end

  def main_contact
    @main_contact ||= @group_item.contact_groups.where(id: arguments[1]).first
  end

  def sub_contacts
    @sub_contacts ||= @group_item.contact_groups.in(id: arguments[2]).to_a
  end
end
