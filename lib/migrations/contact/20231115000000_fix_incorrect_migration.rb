# v1.17.0, v1.18.0, v1.18.1 の次のマイグレーションには問題がある。
#
# - 20221206000000  multi_contacts_on_page
#   （このマイグレーションは、現在は不具合が修正されて 20221206000001 となっているため存在しない）
#
# ページの contact_charge を主でない連絡先の contact_group_name へ移行していた。
# 本マイグレーションでこの問題を修正する。
class SS::Migration20231115000000
  include SS::Migration::Base

  depends_on "20221206000001"

  def change
    # 不具合のあるマイグレーションを適用していなければ、本マイグレーションを適用する必要はない
    return unless problematic_migration_executed

    each_group do |group|
      if group.invalid?
        warn "#{group.name}(#{group.id}): バリデーションエラーがあるため修正を適用できません。"
        warn group.errors.full_messages.join("\n")
        next
      end

      contact_groups = []
      modified = false
      main_contact = group.contact_groups.where(main_state: "main").first
      group.contact_groups.each do |contact|
        # 主連絡先は問題ない
        if contact.main_state == "main"
          contact_groups << contact
          next
        end

        # 問題のあるマイグレーションの実行後に更新されている
        if contact.updated > problematic_migration_executed
          contact_groups << contact
          next
        end

        if contact.contact_group_name.blank? || contact.contact_charge.present?
          contact_groups << contact
          next
        end

        if group.section_name == contact.contact_group_name
          contact_groups << contact
          next
        end

        # 誤ってページの contact_charge を （主ではない）連絡先の contact_group_name へセットしてしまっている。
        contact.contact_charge = contact.contact_group_name
        contact.contact_group_name = main_contact.try(:contact_group_name)
        if group.section_name == contact.contact_group_name
          contact.contact_group_name = nil
        end
        contact.updated = Time.zone.now
        contact_groups << contact
        modified = true
      end
      next unless modified

      group.update(contact_groups: contact_groups)
    end
  end

  private

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

  def each_group(&block)
    criteria = Cms::Group.unscoped
    criteria = criteria.exists(contact_groups: true)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(100) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end
end
