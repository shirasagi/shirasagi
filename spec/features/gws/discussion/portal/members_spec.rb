require 'spec_helper'

describe "gws_discussion_forum_portal", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }

  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 10 }
  let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 20 }
  let!(:group3) { create :gws_group, name: "#{site.name}/#{unique_id}", order: nil }

  let!(:title1) { create :gws_user_title, order: 10 }
  let!(:title2) { create :gws_user_title, order: 20 }
  let!(:title3) { create :gws_user_title, order: 30 }
  let!(:title4) { create :gws_user_title, order: 40 }

  let!(:permissions) do
    %w(
      use_gws_discussion
      read_private_gws_discussion_forums
      edit_private_gws_discussion_forums
      delete_private_gws_discussion_forums)
  end
  let!(:role) { create :gws_role, cur_site: site, permissions: permissions }
  let!(:user1) { create :gws_user, group_ids: [group1.id], title_ids: [title1.id], gws_role_ids: [role.id] }
  let!(:user2) { create :gws_user, group_ids: [group1.id], title_ids: [title2.id], gws_role_ids: [role.id] }
  let!(:user3) { create :gws_user, group_ids: [group2.id], title_ids: [title3.id], gws_role_ids: [role.id] }
  let!(:user4) { create :gws_user, group_ids: [group2.id], title_ids: [title4.id], gws_role_ids: [role.id] }
  let!(:user5) { create :gws_user, group_ids: [group3.id], gws_role_ids: [role.id] }

  let!(:forum) do
    create(:gws_discussion_forum,
      member_group_ids: [group1.id, group2.id, group3.id],
      member_ids: [],
      group_ids: [group1.id, group2.id, group3.id])
  end

  let!(:index_path) { gws_discussion_forum_portal_path(mode: mode, site: site, forum_id: forum) }

  context "readable mode" do
    let!(:mode) { "-" }

    before { login_user(user1) }

    it do
      visit index_path
      wait_for_js_ready

      within ".addon-view.members" do
        expect(page).to have_selector(".gws-discussion-member", count: 3)

        within all(".gws-discussion-member")[0] do
          expect(page).to have_css(".group", text: group1.section_name)
          expect(page).to have_selector(".members li", count: 2)

          within all(".members li")[0] do
            expect(page).to have_css(".long-name", text: user2.name)
            expect(page).to have_css(".user-title", text: title2.name)
          end
          within all(".members li")[1] do
            expect(page).to have_css(".long-name", text: user1.name)
            expect(page).to have_css(".user-title", text: title1.name)
          end
        end
        within all(".gws-discussion-member")[1] do
          expect(page).to have_css(".group", text: group2.section_name)
          expect(page).to have_selector(".members li", count: 2)

          within all(".members li")[0] do
            expect(page).to have_css(".long-name", text: user4.name)
            expect(page).to have_css(".user-title", text: title4.name)
          end
          within all(".members li")[1] do
            expect(page).to have_css(".long-name", text: user3.name)
            expect(page).to have_css(".user-title", text: title3.name)
          end
        end
        within all(".gws-discussion-member")[2] do
          expect(page).to have_css(".group", text: group3.section_name)
          expect(page).to have_selector(".members li", count: 1)

          within all(".members li")[0] do
            expect(page).to have_css(".long-name", text: user5.name)
            expect(page).to have_no_css(".user-title")
          end
        end
      end
    end
  end

  context "editable mode" do
    let!(:mode) { "editable" }

    before { login_user(user1) }

    it do
      visit index_path
      wait_for_js_ready

      within ".addon-view.members" do
        expect(page).to have_selector(".gws-discussion-member", count: 3)

        within all(".gws-discussion-member")[0] do
          expect(page).to have_css(".group", text: group1.section_name)
          expect(page).to have_selector(".members li", count: 2)

          within all(".members li")[0] do
            expect(page).to have_css(".long-name", text: user2.name)
            expect(page).to have_css(".user-title", text: title2.name)
          end
          within all(".members li")[1] do
            expect(page).to have_css(".long-name", text: user1.name)
            expect(page).to have_css(".user-title", text: title1.name)
          end
        end
        within all(".gws-discussion-member")[1] do
          expect(page).to have_css(".group", text: group2.section_name)
          expect(page).to have_selector(".members li", count: 2)

          within all(".members li")[0] do
            expect(page).to have_css(".long-name", text: user4.name)
            expect(page).to have_css(".user-title", text: title4.name)
          end
          within all(".members li")[1] do
            expect(page).to have_css(".long-name", text: user3.name)
            expect(page).to have_css(".user-title", text: title3.name)
          end
        end
        within all(".gws-discussion-member")[2] do
          expect(page).to have_css(".group", text: group3.section_name)
          expect(page).to have_selector(".members li", count: 1)

          within all(".members li")[0] do
            expect(page).to have_css(".long-name", text: user5.name)
            expect(page).to have_no_css(".user-title")
          end
        end
      end
    end
  end
end
