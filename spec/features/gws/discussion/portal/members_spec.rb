require 'spec_helper'

describe "gws_discussion_forum_portal", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:group) { create :gws_group, name: "#{site.name}/#{unique_id}" }

  let!(:forum) do
    create(:gws_discussion_forum, member_group_ids: [group.id], member_ids: [user.id])
  end

  let!(:index_path) { gws_discussion_forum_portal_path(mode: '-', site: site, forum_id: forum) }

  before { login_gws_user }

  context "case1" do
    let!(:title1) { create :gws_user_title, order: 40 }
    let!(:title2) { create :gws_user_title, order: 30 }
    let!(:title3) { create :gws_user_title, order: 20 }
    let!(:title4) { create :gws_user_title, order: 10 }

    let!(:user1) { create :gws_user, group_ids: [group.id], title_ids: [title1.id] }
    let!(:user2) { create :gws_user, group_ids: [group.id], title_ids: [title2.id] }
    let!(:user3) { create :gws_user, group_ids: [site.id], title_ids: [title3.id] }
    let!(:user4) { create :gws_user, group_ids: [site.id], title_ids: [title4.id] }

    let!(:user_with_site_group) do
      u = gws_user
      u.group_ids = [site.id]
      u.save!
      u
    end

    let!(:forum) do
      create(:gws_discussion_forum, member_group_ids: [group.id], member_ids: [user_with_site_group.id, user3.id, user4.id])
    end

    let!(:index_path) { gws_discussion_forum_portal_path(mode: '-', site: site, forum_id: forum) }

    it "#portal" do
      visit index_path
      wait_for_js_ready
      ensure_addon_opened('.addon-view.members')
      within ".addon-view.members" do
        # グループごとに表示されることを確認
        expect(page).to have_selector(".contributor-group", count: 2)
        expect(page).to have_selector("p", count: 5)

        # グループ内のユーザーが役職順で並んでいることを確認
        group_section = page.find(".contributor-group", text: group.section_name)
        members = group_section.all("p")
        expect(members[0]).to have_text user1.name
        expect(members[0]).to have_text title1.name
        expect(members[1]).to have_text user2.name
        expect(members[1]).to have_text title2.name

        site_section = page.find(".contributor-group", text: site.section_name)
        members = site_section.all("p")
        expect(members[0]).to have_text user3.name
        expect(members[0]).to have_text title3.name
        expect(members[1]).to have_text user4.name
        expect(members[1]).to have_text title4.name
        expect(members[2]).to have_text user_with_site_group.name
      end
    end
  end

  context "case2" do
    let!(:title1) { create :gws_user_title, order: 10 }
    let!(:title2) { create :gws_user_title, order: 20 }
    let!(:title3) { create :gws_user_title, order: 30 }
    let!(:title4) { create :gws_user_title, order: 40 }

    let!(:user1) { create :gws_user, group_ids: [group.id], title_ids: [title1.id] }
    let!(:user2) { create :gws_user, group_ids: [group.id], title_ids: [title2.id] }
    let!(:user3) { create :gws_user, group_ids: [site.id], title_ids: [title3.id] }
    let!(:user4) { create :gws_user, group_ids: [site.id], title_ids: [title4.id] }

    let!(:user_with_site_group) do
      u = gws_user
      u.group_ids = [site.id]
      u.save!
      u
    end

    let!(:forum) do
      create(:gws_discussion_forum, member_group_ids: [group.id], member_ids: [user_with_site_group.id, user3.id, user4.id])
    end

    let!(:index_path) { gws_discussion_forum_portal_path(mode: '-', site: site, forum_id: forum) }

    before do
      user4.disable
    end

    it "#portal" do
      visit index_path
      wait_for_js_ready
      ensure_addon_opened('.addon-view.members')
      within ".addon-view.members" do
        expect(page).to have_no_text user4.name
        expect(page).to have_no_text title4.name

        expect(page).to have_selector("p", count: 4)

        # グループ内のユーザーが役職順で並んでいること（orderが大きい順）
        group_section = page.find(".contributor-group", text: group.section_name)
        members = group_section.all("p")
        expect(members[0]).to have_text user2.name # order: 20
        expect(members[0]).to have_text title2.name
        expect(members[1]).to have_text user1.name # order: 10
        expect(members[1]).to have_text title1.name

        site_section = page.find(".contributor-group", text: site.section_name)
        members = site_section.all("p")
        expect(members[0]).to have_text user3.name # order: 30
        expect(members[0]).to have_text title3.name
        expect(members[1]).to have_text user_with_site_group.name
      end
    end
  end

  context "grouped display with section_name" do
    let!(:title1) { create :gws_user_title, order: 40 }
    let!(:title2) { create :gws_user_title, order: 30 }
    let!(:title3) { create :gws_user_title, order: 20 }
    let!(:title4) { create :gws_user_title, order: 10 }

    let!(:user1) { create :gws_user, group_ids: [group.id], title_ids: [title1.id] }
    let!(:user2) { create :gws_user, group_ids: [group.id], title_ids: [title2.id] }
    let!(:user3) { create :gws_user, group_ids: [site.id], title_ids: [title3.id] }
    let!(:user4) { create :gws_user, group_ids: [site.id], title_ids: [title4.id] }

    let!(:user_with_site_group) do
      u = gws_user
      u.group_ids = [site.id]
      u.save!
      u
    end

    let!(:forum) do
      create(:gws_discussion_forum, member_group_ids: [group.id], member_ids: [user_with_site_group.id, user3.id, user4.id])
    end

    let!(:index_path) { gws_discussion_forum_portal_path(mode: '-', site: site, forum_id: forum) }

    it "displays members grouped by section_name" do
      visit index_path
      wait_for_js_ready
      ensure_addon_opened('.addon-view.members')
      within ".addon-view.members" do
        # グループごとの見出しが表示されること
        expect(page).to have_selector(".contributor-group", count: 2)
        expect(page).to have_selector(".contributor", count: 2)

        # グループ名（section_name）が表示されること
        expect(page).to have_text group.section_name
        expect(page).to have_text site.section_name

        # 各グループ内にユーザーが表示されること
        group_section = page.find(".contributor-group", text: group.section_name)
        expect(group_section).to have_text user1.name
        expect(group_section).to have_text user2.name

        site_section = page.find(".contributor-group", text: site.section_name)
        expect(site_section).to have_text user3.name
        expect(site_section).to have_text user4.name
        expect(site_section).to have_text user_with_site_group.name
      end
    end

    it "sorts members within each group by order_by_title" do
      visit index_path
      wait_for_js_ready
      ensure_addon_opened('.addon-view.members')
      within ".addon-view.members" do
        # グループ内のユーザーが役職順で並んでいること
        group_section = page.find(".contributor-group", text: group.section_name)
        members = group_section.all("p")
        expect(members[0]).to have_text user1.name # order: 40
        expect(members[0]).to have_text title1.name
        expect(members[1]).to have_text user2.name # order: 30
        expect(members[1]).to have_text title2.name

        site_section = page.find(".contributor-group", text: site.section_name)
        members = site_section.all("p")
        expect(members[0]).to have_text user3.name # order: 20
        expect(members[0]).to have_text title3.name
        expect(members[1]).to have_text user4.name # order: 10
        expect(members[1]).to have_text title4.name
        expect(members[2]).to have_text user_with_site_group.name
      end
    end
  end

  context "group order sorting" do
    let!(:group1) { create :gws_group, name: "#{site.name}/グループ1", order: 10 }
    let!(:group2) { create :gws_group, name: "#{site.name}/グループ2", order: 20 }
    let!(:group3) { create :gws_group, name: "#{site.name}/グループ3", order: 5 }

    let!(:user_group1) { create :gws_user, group_ids: [group1.id] }
    let!(:user_group2) { create :gws_user, group_ids: [group2.id] }
    let!(:user_group3) { create :gws_user, group_ids: [group3.id] }

    let!(:forum_with_multiple_groups) do
      create(:gws_discussion_forum, member_group_ids: [group1.id, group2.id, group3.id],
member_ids: [user_group1.id, user_group2.id, user_group3.id])
    end

    let!(:index_path_multiple) { gws_discussion_forum_portal_path(mode: '-', site: site, forum_id: forum_with_multiple_groups) }

    it "sorts groups by order field" do
      visit index_path_multiple
      wait_for_js_ready
      ensure_addon_opened('.addon-view.members')
      within ".addon-view.members" do
        # グループがorder順で表示されること（5 → 10 → 20）
        contributors = page.all(".contributor")
        expect(contributors[0]).to have_text group3.section_name # order: 5
        expect(contributors[1]).to have_text group1.section_name # order: 10
        expect(contributors[2]).to have_text group2.section_name # order: 20
      end
    end
  end

  context "users without group" do
    # group_idsが必須のため、validate: falseでグループなしのユーザーを作成
    let!(:user_no_group) do
      user = build :gws_user, group_ids: []
      user.save(validate: false)
      user
    end

    let!(:forum_no_group) do
      create(:gws_discussion_forum, member_ids: [user_no_group.id])
    end

    let!(:index_path_no_group) { gws_discussion_forum_portal_path(mode: '-', site: site, forum_id: forum_no_group) }

    it "displays users without group at the end" do
      visit index_path_no_group
      wait_for_js_ready
      ensure_addon_opened('.addon-view.members')
      within ".addon-view.members" do
        # グループがないユーザーは最後に表示されること
        expect(page).to have_selector(".contributor-group")
        expect(page).to have_text user_no_group.name

        # グループ見出しは表示されないこと（gws_main_groupがnilを返すため）
        contributors = page.all(".contributor")
        expect(contributors).to be_empty
      end
    end
  end

  context "groups with nil order" do
    let!(:group_with_order) { create :gws_group, name: "#{site.name}/グループ1", order: 10 }
    let!(:group_nil_order1) { create :gws_group, name: "#{site.name}/グループ2", order: nil }
    let!(:group_nil_order2) { create :gws_group, name: "#{site.name}/グループ3", order: nil }
    let!(:group_large_order) { create :gws_group, name: "#{site.name}/グループ4", order: 999_999 }

    let!(:user_with_order) { create :gws_user, group_ids: [group_with_order.id] }
    let!(:user_nil_order1_1) { create :gws_user, group_ids: [group_nil_order1.id] }
    let!(:user_nil_order1_2) { create :gws_user, group_ids: [group_nil_order1.id] }
    let!(:user_nil_order2_1) { create :gws_user, group_ids: [group_nil_order2.id] }
    let!(:user_nil_order2_2) { create :gws_user, group_ids: [group_nil_order2.id] }
    let!(:user_large_order) { create :gws_user, group_ids: [group_large_order.id] }

    let!(:forum_nil_order) do
      create(:gws_discussion_forum,
        member_group_ids: [group_with_order.id, group_nil_order1.id, group_nil_order2.id, group_large_order.id],
        member_ids: [user_with_order.id, user_nil_order1_1.id, user_nil_order1_2.id, user_nil_order2_1.id, user_nil_order2_2.id,
                     user_large_order.id])
    end

    let!(:index_path_nil_order) { gws_discussion_forum_portal_path(mode: '-', site: site, forum_id: forum_nil_order) }

    it "sorts groups with nil order at the end" do
      visit index_path_nil_order
      wait_for_js_ready
      ensure_addon_opened('.addon-view.members')
      within ".addon-view.members" do
        contributors = page.all(".contributor")
        expect(contributors[0]).to have_text group_with_order.section_name
        expect(contributors[1]).to have_text group_large_order.section_name
        expect(page).to have_text group_nil_order1.section_name
        expect(page).to have_text group_nil_order2.section_name
      end
    end

    it "displays multiple members in groups with nil order" do
      visit index_path_nil_order
      wait_for_js_ready
      ensure_addon_opened('.addon-view.members')
      within ".addon-view.members" do
        group1_section = page.find(".contributor-group", text: group_nil_order1.section_name)
        expect(group1_section).to have_text user_nil_order1_1.name
        expect(group1_section).to have_text user_nil_order1_2.name

        group2_section = page.find(".contributor-group", text: group_nil_order2.section_name)
        expect(group2_section).to have_text user_nil_order2_1.name
        expect(group2_section).to have_text user_nil_order2_2.name
      end
    end
  end

  context "multiple users without group" do
    let!(:group_with_order) { create :gws_group, name: "#{site.name}/グループ1", order: 10 }
    let!(:user_with_group) { create :gws_user, group_ids: [group_with_order.id] }

    let!(:user_no_group1) do
      user = build :gws_user, group_ids: []
      user.save(validate: false)
      user
    end

    let!(:user_no_group2) do
      user = build :gws_user, group_ids: []
      user.save(validate: false)
      user
    end

    let!(:forum_multiple_no_group) do
      create(:gws_discussion_forum,
        member_group_ids: [group_with_order.id],
        member_ids: [user_with_group.id, user_no_group1.id, user_no_group2.id])
    end

    let!(:index_path_multiple_no_group) do
      gws_discussion_forum_portal_path(mode: '-', site: site, forum_id: forum_multiple_no_group)
    end

    it "displays multiple users without group at the end" do
      visit index_path_multiple_no_group
      wait_for_js_ready
      ensure_addon_opened('.addon-view.members')
      within ".addon-view.members" do
        contributors = page.all(".contributor")
        expect(contributors[0]).to have_text group_with_order.section_name

        group_section = page.find(".contributor-group", text: group_with_order.section_name)
        expect(group_section).to have_text user_with_group.name

        no_group_section = page.find(".contributor-group.no-group-header")
        expect(no_group_section).to have_text user_no_group1.name
        expect(no_group_section).to have_text user_no_group2.name

        all_contributor_groups = page.all(".contributor-group")
        expect(all_contributor_groups.length).to eq 2
        expect(all_contributor_groups[0]).to have_text group_with_order.section_name
        expect(page).to have_selector(".contributor-group.no-group-header")
      end
    end
  end
end
