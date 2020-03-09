FactoryBot.define do
  trait :gws_role do
    cur_site { gws_site }
    cur_user { gws_user }
    name { "role-#{unique_id}" }
    permissions []
    permission_level 1
  end

  trait :gws_role_admin do
    permissions { Gws::Role.permission_names }
    permission_level 3
  end

  trait :gws_role_notice_admin do
    permission_level 3
    after(:build) do |item|
      item.permissions += Gws::Role.permission_names.select { |name| name.include?('gws_notice') }
    end
  end

  trait :gws_role_notice_editor do
    after(:build) do |item|
      item.permissions += %w(
        use_gws_notice
        delete_private_gws_notices
        edit_private_gws_notices
        read_private_gws_notices
        read_private_gws_notice_categories
      )
    end
  end

  trait :gws_role_notice_reader do
    after(:build) do |item|
      item.permissions += %w(
        use_gws_notice
        read_private_gws_notices
      )
    end
  end

  trait :gws_role_schedule_plan_editor do
    after(:build) do |item|
      item.permissions += %w(
        use_private_gws_schedule_plans
        read_private_gws_schedule_plans
        edit_private_gws_schedule_plans
        delete_private_gws_schedule_plans
        read_private_gws_schedule_categories
      )
    end
  end

  trait :gws_role_schedule_todo_editor do
    after(:build) do |item|
      item.permissions += %w(
        use_private_gws_schedule_todos
        read_private_gws_schedule_todos
        edit_private_gws_schedule_todos
        delete_private_gws_schedule_todos
        read_private_gws_schedule_todo_categories
      )
    end
  end

  trait :gws_role_facility_item_user do
    after(:build) do |item|
      item.permissions += %w(
        use_private_gws_facility_plans
        read_other_gws_facility_items
        read_private_gws_facility_items
      )
    end
  end

  trait :gws_role_facility_item_admin do
    after(:build) do |item|
      item.permissions += %w(
        use_private_gws_facility_plans
        read_other_gws_facility_items
        read_private_gws_facility_items
        edit_private_gws_facility_items
      )
    end
  end

  trait :gws_role_attendance_user do
    after(:build) do |item|
      item.permissions += %w(
        use_gws_attendance_time_cards
      )
    end
  end

  trait :gws_role_attendance_editor do
    after(:build) do |item|
      item.permissions += %w(
        use_gws_attendance_time_cards
        edit_gws_attendance_time_cards
      )
    end
  end

  trait :gws_role_board_user do
    after(:build) do |item|
      item.permissions += %w(
        use_gws_board
      )
    end
  end

  trait :gws_role_board_admin do
    after(:build) do |item|
      item.permissions += %w(
        use_gws_board
        read_private_gws_board_topics
        edit_private_gws_board_topics
        delete_private_gws_board_topics
        trash_private_gws_board_topics
        read_private_gws_board_categories
        edit_private_gws_board_categories
        delete_private_gws_board_categories
      )
    end
  end

  trait :gws_role_portal_user_use do
    after(:build) do |item|
      item.permissions += %w(
        use_gws_portal_user_settings
      )
    end
  end

  trait :gws_role_portal_organization_use do
    after(:build) do |item|
      item.permissions += %w(
        use_gws_portal_organization_settings
      )
    end
  end

  factory :gws_role, class: Gws::Role, traits: [:gws_role]

  factory :gws_role_admin, class: Gws::Role, traits: [:gws_role, :gws_role_admin]

  factory :gws_role_notice_admin, class: Gws::Role, traits: [:gws_role, :gws_role_notice_admin]

  factory :gws_role_notice_editor, class: Gws::Role, traits: [:gws_role, :gws_role_notice_editor]

  factory :gws_role_notice_reader, class: Gws::Role, traits: [:gws_role, :gws_role_notice_reader]

  factory :gws_role_schedule_plan_editor, class: Gws::Role, traits: [:gws_role, :gws_role_schedule_plan_editor]

  factory :gws_role_schedule_todo_editor, class: Gws::Role, traits: [:gws_role, :gws_role_schedule_todo_editor]

  factory :gws_role_attendance_user, class: Gws::Role, traits: [:gws_role, :gws_role_attendance_user]

  factory :gws_role_attendance_editor, class: Gws::Role, traits: [:gws_role, :gws_role_attendance_editor]

  factory :gws_role_portal_user_use, class: Gws::Role, traits: [:gws_role, :gws_role_portal_user_use]

  factory :gws_role_portal_organization_use, class: Gws::Role, traits: [:gws_role, :gws_role_portal_organization_use]
end
