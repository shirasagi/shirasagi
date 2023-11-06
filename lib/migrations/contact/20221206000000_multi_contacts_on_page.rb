class SS::Migration20221206000000
  include SS::Migration::Base

  depends_on "20221109000000"

  def change
    each_page do |page|
      group = id_group_map[page.contact_group_id]
      next if group.blank? # maybe group has been deleted

      contact = group.contact_groups.where(
        contact_group_name: page.contact_group_name, contact_charge: page.contact_charge,
        contact_tel: page.contact_tel, contact_fax: page.contact_fax, contact_email: page.contact_email,
        contact_postal_code: page.contact_postal_code, contact_address: page.contact_address,
        contact_link_url: page.contact_link_url, contact_link_name: page.contact_link_name
      ).first

      if contact.present?
        page.set(contact_group_relation: "related", contact_group_contact_id: contact.id)
        next
      end

      contact = group.contact_groups.create(
        name: "#{group.section_name} #{group.contact_groups.count + 1}",
        contact_group_name: page.contact_group_name, contact_charge: page.contact_charge,
        contact_tel: page.contact_tel, contact_fax: page.contact_fax, contact_email: page.contact_email,
        contact_postal_code: page.contact_postal_code, contact_address: page.contact_address,
        contact_link_url: page.contact_link_url, contact_link_name: page.contact_link_name)
      page.set(contact_group_relation: "related", contact_group_contact_id: contact.id)
    end
  end

  private

  def id_site_map
    @id_site_map ||= Cms::Site.all.unscoped.to_a.index_by(&:id)
  end

  def id_group_map
    @id_group_map ||= Cms::Group.all.unscoped.to_a.index_by(&:id)
  end

  PAGE_CONTACT_ATTRIBUTES = %i[
    contact_group_name contact_charge contact_tel contact_fax contact_email contact_postal_code contact_address
    contact_link_url contact_link_name
  ].freeze

  def each_page(&block)
    criteria = Cms::Page.all.exists(contact_group_id: true).exists(contact_group_relation: false)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      criteria.in(id: ids).to_a.each do |page|
        if PAGE_CONTACT_ATTRIBUTES.all? { |attr| page.send(attr).blank? }
          page.set(contact_group_relation: "unrelated")
          next
        end

        site = id_site_map[page.site_id]
        group = id_group_map[page.contact_group_id]
        if site.blank? || group.blank?
          # maybe site has been deleted
          page.set(contact_group_relation: "unrelated")
          next
        end

        page.site = site
        page.cur_site = site
        page.contact_group = group

        yield page
      end
    end
  end
end
