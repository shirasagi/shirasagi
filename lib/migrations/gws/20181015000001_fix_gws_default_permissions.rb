class SS::Migration20181015000001
  include SS::Migration::Base

  depends_on "20181015000000"

  DEFAULT_PERMISSIONS = %w(
    use_private_gws_schedule_plans use_private_gws_schedule_todos use_private_gws_facility_plans
    edit_gws_bookmarks edit_gws_personal_addresses use_gws_report use_gws_circular use_gws_survey
    use_gws_staff_record use_gws_workflow use_gws_monitor use_gws_board use_gws_faq use_gws_qna
    use_gws_discussion use_gws_share use_gws_shared_address use_gws_elasticsearch read_gws_organization
  ).freeze

  ADMIN_PERMISSIONS = %w().freeze

  def change
    all_ids = Gws::Role.all.pluck(:id)
    all_ids.each_slice(20) do |ids|
      roles = Gws::Role.all.in(id: ids).to_a
      roles.each do |role|
        next if (DEFAULT_PERMISSIONS - role.permissions).blank?

        role.permissions += DEFAULT_PERMISSIONS
        if role.permissions.include?("edit_gws_groups")
          role.permissions += ADMIN_PERMISSIONS
        end
        role.permissions.uniq!
        role.without_record_timestamps { role.save! }
      end
    end
  end
end
