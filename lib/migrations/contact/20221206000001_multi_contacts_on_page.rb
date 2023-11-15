# 20221206000000 の不具合修正版
class SS::Migration20221206000001
  include SS::Migration::Base

  depends_on "20221109000000"

  def change
    # 不具合のあるマイグレーションが適用済みであれば、本マイグレーションを適用することで二重に連絡先が生成されるかもしれない。
    # よって、本マイグレーションを適用しないようにする。
    return if problematic_migration_executed

    each_page do |page|
      group = id_group_map[page.contact_group_id]
      next if group.blank? # maybe group has been deleted

      # 以前の仕様では contact_group_name はページによる変更はできず、常にグループ側の contact_group_name を参照していた
      contact_group_name = trim(group.contact_group_name)
      contact_charge = trim(page.contact_charge)
      contact_tel = trim(page.contact_tel)
      contact_fax = trim(page.contact_fax)
      contact_email = trim(page.contact_email)
      contact_link_url = trim(page.contact_link_url)
      contact_link_name = trim(page.contact_link_name)

      contact = group.contact_groups.where(
        contact_group_name: contact_group_name, contact_charge: contact_charge,
        contact_tel: contact_tel, contact_fax: contact_fax, contact_email: contact_email,
        contact_link_url: contact_link_url, contact_link_name: contact_link_name
      ).first

      if contact.present?
        page.set(contact_group_relation: "related", contact_group_contact_id: contact.id)
        next
      end

      contact = group.contact_groups.create(
        name: "#{group.section_name} #{group.contact_groups.count + 1}",
        contact_group_name: contact_group_name, contact_charge: contact_charge,
        contact_tel: contact_tel, contact_fax: contact_fax, contact_email: contact_email,
        contact_link_url: contact_link_url, contact_link_name: contact_link_name)
      page.set(contact_group_relation: "related", contact_group_contact_id: contact.id)
    end
  end

  private

  def trim(text)
    return text if text.blank?
    text.strip.presence
  end

  def id_site_map
    @id_site_map ||= Cms::Site.all.unscoped.to_a.index_by(&:id)
  end

  def id_group_map
    @id_group_map ||= Cms::Group.all.unscoped.to_a.index_by(&:id)
  end

  PAGE_CONTACT_ATTRIBUTES = %i[
    contact_group_name contact_charge contact_tel contact_fax contact_email contact_link_url contact_link_name
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

  def problematic_migration_executed
    return @problematic_migration_executed if instance_variable_defined?(:@problematic_migration_executed)

    # 不具合のあるマイグレーションを適用した日時を検索
    criteria = SS::Migration.where(version: "20221206000000")
    migration = criteria.first
    unless migration
      return @problematic_migration_executed = nil
    end

    @problematic_migration_executed = migration.created.in_time_zone
  end
end
