# #5418: contact_group_contact_id がセットされなければならないのに空で保存されたページを修正する
class SS::Migration20240913000000
  include SS::Migration::Base

  # depends_on "20240903000000"

  def change
    each_item do |item|
      site = find_site(item.site_id)
      next if site.blank?

      item.site = site
      item.cur_site = site

      next if item.contact_group_relation.present?
      next if item.contact_group_contact_id.present?

      group = find_group(item.contact_group_id)
      next if group.blank?

      item.contact_group = group

      contact = group.contact_groups.where(main_state: "main").first
      next if contact.blank?

      item.contact_group_contact = contact
      item.contact_tel = contact.contact_tel
      item.contact_fax = contact.contact_fax
      item.contact_email = contact.contact_email
      item.contact_link_url = contact.contact_link_url
      item.contact_link_name = contact.contact_link_name

      item.without_record_timestamps { item.save }
    end
  end

  private

  def each_item(&block)
    criteria = Cms::Page.all
    criteria = criteria.exists(contact_group_id: true, contact_group_relation: false, contact_group_contact_id: false)
    criteria = criteria.ne(contact_state: "hide")

    contact_attributes = %i[
      contact_tel
      contact_fax
      contact_email
      contact_link_url
      contact_link_name
    ]

    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      items = criteria.in(id: ids).to_a
      items = items.select { |page| contact_attributes.any? { |attr| page.send(attr).present? rescue false } }
      items.each(&block)
    end
  end

  def find_site(site_id)
    return if site_id.blank?

    @all_sites ||= Cms::Site.unscoped.to_a
    @id_site_map ||= @all_sites.index_by(&:id)
    @id_site_map[site_id]
  end

  def find_group(group_id)
    return if group_id.blank?

    @all_groups ||= Cms::Group.unscoped.to_a
    @id_group_map ||= @all_groups.index_by(&:id)
    @id_group_map[group_id]
  end
end
