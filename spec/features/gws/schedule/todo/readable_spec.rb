require 'spec_helper'

describe "gws_schedule_todo_readables", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:role) { create :gws_role, :gws_role_schedule_todo_editor, cur_site: site }
  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  # user1: 担当ユーザー（作成者）
  let!(:user1) { create :gws_user, gws_role_ids: [ role.id ], group_ids: [ group1.id ] }
  # user2: 閲覧ユーザー
  let!(:user2) { create :gws_user, gws_role_ids: [ role.id ], group_ids: [ group2.id ] }
  # user3: 担当・閲覧・管理のいずれでもない
  let!(:user3) { create :gws_user, gws_role_ids: [ role.id ], group_ids: [ group2.id ] }
  # user4: 管理ユーザー
  let!(:user4) { create :gws_user, gws_role_ids: [ role.id ], group_ids: [ group2.id ] }
  let!(:item) do
    create(
      :gws_schedule_todo, cur_site: site, cur_user: user1, member_ids: [ user1.id ], member_group_ids: [],
      readable_setting_range: 'select', readable_member_ids: [ user2.id ], readable_group_ids: [],
      group_ids: [], user_ids: [ user1.id, user4.id ]
    )
  end
  let(:show_path) { gws_schedule_todo_readable_path(site: site, category: Gws::Schedule::TodoCategory::ALL.id, id: item) }

  context "with member user" do
    before { login_user user1 }

    it do
      visit show_path
      expect(status_code).to eq 200
      within "#addon-basic" do
        expect(page).to have_content(item.name)
      end
    end
  end

  context "with readable user" do
    before { login_user user2 }

    it do
      visit show_path
      expect(status_code).to eq 200
      within "#addon-basic" do
        expect(page).to have_content(item.name)
      end
    end
  end

  context "with manageable user" do
    before { login_user user4 }

    it do
      visit show_path
      expect(status_code).to eq 200
      within "#addon-basic" do
        expect(page).to have_content(item.name)
      end
    end
  end

  context "with unrelated user" do
    let(:path_options) { { site: site, category: Gws::Schedule::TodoCategory::ALL.id, id: item } }

    before { login_user user3 }

    it do
      visit show_path
      expect(status_code).to eq 200
      within "#addon-basic" do
        expect(page).to have_css("dd", text: I18n.t("gws/schedule.private_plan"))
        expect(page).to have_no_content(item.name)
      end
      expect(page.title).not_to include(item.name)

      visit popup_gws_schedule_todo_readable_path(path_options)
      expect(status_code).to eq 200
      expect(page).to have_css(".popup-title", text: I18n.t("gws/schedule.private_plan"))
      expect(page).to have_no_content(item.name)

      visit edit_gws_schedule_todo_readable_path(path_options)
      expect(status_code).to eq 404

      visit copy_gws_schedule_todo_readable_path(path_options)
      expect(status_code).to eq 404

      visit soft_delete_gws_schedule_todo_readable_path(path_options)
      expect(status_code).to eq 404

      visit finish_gws_schedule_todo_readable_path(path_options)
      expect(status_code).to eq 404
    end
  end

  context "with user in the same group as member on private todo" do
    # user5: 担当ユーザー（user1）と同じグループに所属するが、担当・閲覧・管理のいずれでもない
    let!(:user5) { create :gws_user, gws_role_ids: [ role.id ], group_ids: [ group1.id ] }
    let!(:private_item) do
      create(
        :gws_schedule_todo, cur_site: site, cur_user: user1, member_ids: [ user1.id ], member_group_ids: [],
        readable_setting_range: 'private', group_ids: [], user_ids: [ user1.id ]
      )
    end
    let(:path_options) { { site: site, category: Gws::Schedule::TodoCategory::ALL.id, id: private_item } }

    before { login_user user5 }

    it do
      expect(private_item.readable_member_ids).to eq [ user1.id ]
      expect(private_item.readable_group_ids).to be_blank

      visit gws_schedule_todo_readable_path(path_options)
      expect(status_code).to eq 200
      within "#addon-basic" do
        expect(page).to have_css("dd", text: I18n.t("gws/schedule.private_plan"))
        expect(page).to have_no_content(private_item.name)
      end
      expect(page.title).not_to include(private_item.name)

      visit popup_gws_schedule_todo_readable_path(path_options)
      expect(status_code).to eq 200
      expect(page).to have_css(".popup-title", text: I18n.t("gws/schedule.private_plan"))
      expect(page).to have_no_content(private_item.name)
    end
  end

  context "with readable user operates todo" do
    let(:path_options) { { site: site, category: Gws::Schedule::TodoCategory::ALL.id, id: item } }

    before { login_user user2 }

    it do
      visit edit_gws_schedule_todo_readable_path(path_options)
      expect(status_code).to eq 403

      visit soft_delete_gws_schedule_todo_readable_path(path_options)
      expect(status_code).to eq 403

      visit finish_gws_schedule_todo_readable_path(path_options)
      expect(status_code).to eq 403
    end
  end

  context "with manageable user operates todo" do
    let(:path_options) { { site: site, category: Gws::Schedule::TodoCategory::ALL.id, id: item } }

    before { login_user user4 }

    it do
      visit edit_gws_schedule_todo_readable_path(path_options)
      expect(status_code).to eq 200

      visit soft_delete_gws_schedule_todo_readable_path(path_options)
      expect(status_code).to eq 200

      visit finish_gws_schedule_todo_readable_path(path_options)
      expect(status_code).to eq 200
    end
  end

  context "with readable user requests bulk operations" do
    let(:path_options) { { site: site, category: Gws::Schedule::TodoCategory::ALL.id } }

    before { login_user user2 }

    it do
      page.driver.post finish_all_gws_schedule_todo_readables_path(path_options), ids: [ item.id ]
      page.driver.post soft_delete_all_gws_schedule_todo_readables_path(path_options), ids: [ item.id ]

      item.reload
      expect(item.todo_state).to eq "unfinished"
      expect(item.deleted).to be_blank
      expect(Gws::Schedule::TodoComment.where(todo_id: item.id).count).to eq 0
    end

    context "when todo is finished" do
      before { item.set(achievement_rate: 100, todo_state: "finished") }

      it do
        page.driver.post revert_all_gws_schedule_todo_readables_path(path_options), ids: [ item.id ]

        item.reload
        expect(item.todo_state).to eq "finished"
        expect(Gws::Schedule::TodoComment.where(todo_id: item.id).count).to eq 0
      end
    end
  end

  context "with manageable user requests bulk operations" do
    let(:path_options) { { site: site, category: Gws::Schedule::TodoCategory::ALL.id } }

    before { login_user user4 }

    it do
      page.driver.post finish_all_gws_schedule_todo_readables_path(path_options), ids: [ item.id ]
      item.reload
      expect(item.todo_state).to eq "finished"

      page.driver.post revert_all_gws_schedule_todo_readables_path(path_options), ids: [ item.id ]
      item.reload
      expect(item.todo_state).to eq "unfinished"
      expect(Gws::Schedule::TodoComment.where(todo_id: item.id).count).to eq 2

      page.driver.post soft_delete_all_gws_schedule_todo_readables_path(path_options), ids: [ item.id ]
      item.reload
      expect(item.deleted).to be_present
    end
  end

  context "with unrelated user via user's calendar", js: true do
    before { login_user user3 }

    it do
      visit gws_schedule_user_plans_path(site: site, user: user1)
      wait_for_js_ready
      within ".fc-daygrid-body" do
        expect(page).to have_css(".fc-event.fc-event-todo .fc-event-title", text: I18n.t("gws/schedule.private_plan"))
        first(".fc-event.fc-event-todo").click
      end

      within "#addon-basic" do
        expect(page).to have_css("dd", text: I18n.t("gws/schedule.private_plan"))
      end
      expect(page.title).not_to include(item.name)
    end
  end

  context "with readable user via user's calendar", js: true do
    before { login_user user2 }

    it do
      visit gws_schedule_user_plans_path(site: site, user: user1)
      wait_for_js_ready
      within ".fc-daygrid-body" do
        expect(page).to have_css(".fc-event.fc-event-todo .fc-event-title", text: item.name)
        first(".fc-event.fc-event-todo").click
      end

      within "#addon-basic" do
        expect(page).to have_content(item.name)
      end
    end
  end
end
