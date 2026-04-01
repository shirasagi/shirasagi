require 'spec_helper'

describe "gws_discussion_forum_portal", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:group) { create :gws_group, name: "#{site.name}/#{unique_id}", order: nil }

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
        expect(page).to have_selector(".gws-discussion-member", count: 2)

        # グループ内のユーザーが役職順で並んでいることを確認
        within all(".gws-discussion-member")[0] do
          expect(page).to have_css(".group", text: site.section_name)
          within all(".members li")[0] do
            expect(page).to have_css(".long-name", text: user3.name)
            expect(page).to have_css(".user-title", text: title3.name)
          end
          within all(".members li")[1] do
            expect(page).to have_css(".long-name", text: user4.name)
            expect(page).to have_css(".user-title", text: title4.name)
          end
          within all(".members li")[2] do
            expect(page).to have_css(".long-name", text: user_with_site_group.name)
            expect(page).to have_no_css(".user-title")
          end
        end
        within all(".gws-discussion-member")[1] do
          expect(page).to have_css(".group", text: group.section_name)
          within all(".members li")[0] do
            expect(page).to have_css(".long-name", text: user1.name)
            expect(page).to have_css(".user-title", text: title1.name)
          end
          within all(".members li")[1] do
            expect(page).to have_css(".long-name", text: user2.name)
            expect(page).to have_css(".user-title", text: title2.name)
          end
        end
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
        expect(page).to have_selector(".gws-discussion-member", count: 2)

        # グループ内のユーザーが役職順で並んでいること（orderが大きい順）
        within all(".gws-discussion-member")[0] do
          expect(page).to have_css(".group", text: site.section_name)
          within all(".members li")[0] do
            expect(page).to have_css(".long-name", text: user3.name) # order: 30
            expect(page).to have_css(".user-title", text: title3.name)
          end
          within all(".members li")[1] do
            expect(page).to have_css(".long-name", text: user_with_site_group.name)
            expect(page).to have_no_css(".user-title")
          end
        end
        within all(".gws-discussion-member")[1] do
          expect(page).to have_css(".group", text: group.section_name)
          within all(".members li")[0] do
            expect(page).to have_css(".long-name", text: user2.name) # order: 20
            expect(page).to have_css(".user-title", text: title2.name)
          end
          within all(".members li")[1] do
            expect(page).to have_css(".long-name", text: user1.name) # order: 10
            expect(page).to have_css(".user-title", text: title1.name)
          end
        end
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
        # グループごとに表示されることを確認
        expect(page).to have_selector(".gws-discussion-member", count: 2)

        # グループ名（section_name）が表示されること
        within all(".gws-discussion-member")[0] do
          expect(page).to have_css(".group", text: site.section_name)
          within all(".members li")[0] do
            expect(page).to have_css(".long-name", text: user3.name)
            expect(page).to have_css(".user-title", text: title3.name)
          end
          within all(".members li")[1] do
            expect(page).to have_css(".long-name", text: user4.name)
            expect(page).to have_css(".user-title", text: title4.name)
          end
          within all(".members li")[2] do
            expect(page).to have_css(".long-name", text: user_with_site_group.name)
            expect(page).to have_no_css(".user-title")
          end
        end
        within all(".gws-discussion-member")[1] do
          expect(page).to have_css(".group", text: group.section_name)
          within all(".members li")[0] do
            expect(page).to have_css(".long-name", text: user1.name)
            expect(page).to have_css(".user-title", text: title1.name)
          end
          within all(".members li")[1] do
            expect(page).to have_css(".long-name", text: user2.name)
            expect(page).to have_css(".user-title", text: title2.name)
          end
        end
      end
    end

    it "sorts members within each group by order_by_title" do
      visit index_path
      wait_for_js_ready
      ensure_addon_opened('.addon-view.members')
      within ".addon-view.members" do
        # グループ内のユーザーが役職順で並んでいること
        within all(".gws-discussion-member")[0] do
          expect(page).to have_css(".group", text: site.section_name)
          within all(".members li")[0] do
            expect(page).to have_css(".long-name", text: user3.name) # order: 20
            expect(page).to have_css(".user-title", text: title3.name)
          end
          within all(".members li")[1] do
            expect(page).to have_css(".long-name", text: user4.name) # order: 10
            expect(page).to have_css(".user-title", text: title4.name)
          end
        end
        within all(".gws-discussion-member")[1] do
          expect(page).to have_css(".group", text: group.section_name)
          within all(".members li")[0] do
            expect(page).to have_css(".long-name", text: user1.name) # order: 40
            expect(page).to have_css(".user-title", text: title1.name)
          end
          within all(".members li")[1] do
            expect(page).to have_css(".long-name", text: user2.name) # order: 30
            expect(page).to have_css(".user-title", text: title2.name)
          end
        end
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
        within all(".gws-discussion-member")[0] do
          expect(page).to have_css(".group", text: group3.section_name)
        end
        within all(".gws-discussion-member")[1] do
          expect(page).to have_css(".group", text: group1.section_name)
        end
        within all(".gws-discussion-member")[2] do
          expect(page).to have_css(".group", text: group2.section_name)
        end
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
        within all(".gws-discussion-member")[0] do
          expect(page).to have_css(".group", text: group_with_order.section_name)
        end
        within all(".gws-discussion-member")[1] do
          expect(page).to have_css(".group", text: group_large_order.section_name)
        end
        within all(".gws-discussion-member")[2] do
          expect(page).to have_css(".group", text: group_nil_order1.section_name)
          expect(page).to have_text(user_nil_order1_1.name)
          expect(page).to have_text(user_nil_order1_2.name)
        end
        within all(".gws-discussion-member")[3] do
          expect(page).to have_css(".group", text: group_nil_order2.section_name)
          expect(page).to have_text(user_nil_order2_1.name)
          expect(page).to have_text(user_nil_order2_2.name)
        end
      end
    end
  end
end
