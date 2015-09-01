gws_admin_role = Gws::Role.find_or_create_by name: "GWS管理者"
gws_admin_role.update(
  name: "GWS管理者",
  permission_level: 3,
  permissions: %w(
    read_gws_users
    edit_gws_users

    read_other_gws_board_posts
    read_private_gws_board_posts
    edit_other_gws_board_posts
    edit_private_gws_board_posts
    delete_other_gws_board_posts
    delete_private_gws_board_posts

    read_other_gws_schedule_plans
    read_private_gws_schedule_plans
    edit_other_gws_schedule_plans
    edit_private_gws_schedule_plans
    delete_other_gws_schedule_plans
    delete_private_gws_schedule_plans

    read_other_gws_schedule_categories
    read_private_gws_schedule_categories
    edit_other_gws_schedule_categories
    edit_private_gws_schedule_categories
    delete_other_gws_schedule_categories
    delete_private_gws_schedule_categories

    read_other_gws_schedule_facilities
    read_private_gws_schedule_facilities
    edit_other_gws_schedule_facilities
    edit_private_gws_schedule_facilities
    delete_other_gws_schedule_facilities
    delete_private_gws_schedule_facilities

    read_other_gws_reservation_plans
    read_private_gws_reservation_plans
    edit_other_gws_reservation_plans
    edit_private_gws_reservation_plans
    delete_other_gws_reservation_plans
    delete_private_gws_reservation_plans

    read_other_gws_share_files
    read_private_gws_share_files
    edit_other_gws_share_files
    edit_private_gws_share_files
    delete_other_gws_share_files
    delete_private_gws_share_files
  )
)

admin_user = Gws::User.find_by uid: "admin"
admin_user.update gws_role_ids: [gws_admin_role.id]
