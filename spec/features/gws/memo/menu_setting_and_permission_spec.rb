require 'spec_helper'

describe 'gws_memo_messages', type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }

  context "menu is visible" do
    context "user has permissions" do
      let!(:role) { create :gws_role, :gws_role_portal_user_use, :gws_role_memo_reader, cur_site: site }
      let!(:user) { create :gws_user, group_ids: admin.group_ids, gws_role_ids: [ role.id ] }

      it do
        login_user user, to: gws_portal_path(site: site)

        link = gws_memo_messages_path(site: site, folder: "INBOX")
        within ".main-navi" do
          expect(page).to have_link(site.menu_memo_effective_label, href: link)
        end
        within ".gws-memo-message" do
          expect(page).to have_link(href: link)
        end
      end
    end

    context "user has no permissions" do
      let!(:role) { create :gws_role, :gws_role_portal_user_use, cur_site: site }
      let!(:user) { create :gws_user, group_ids: admin.group_ids, gws_role_ids: [ role.id ] }

      it do
        login_user user, to: gws_portal_path(site: site)

        within ".main-navi" do
          expect(page).to have_no_link(site.menu_memo_effective_label)
        end
        expect(page).to have_no_css(".gws-memo-message")
      end
    end
  end

  context "menu is hidden" do
    before do
      site.update!(menu_memo_state: "hide")
    end

    context "user has permissions" do
      let!(:role) { create :gws_role, :gws_role_portal_user_use, :gws_role_memo_reader, cur_site: site }
      let!(:user) { create :gws_user, group_ids: admin.group_ids, gws_role_ids: [ role.id ] }

      it do
        login_user user, to: gws_portal_path(site: site)

        within ".main-navi" do
          expect(page).to have_no_link(site.menu_memo_effective_label)
        end
        expect(page).to have_no_css(".gws-memo-message")
      end
    end

    context "user has no permissions" do
      let!(:role) { create :gws_role, :gws_role_portal_user_use, cur_site: site }
      let!(:user) { create :gws_user, group_ids: admin.group_ids, gws_role_ids: [ role.id ] }

      it do
        login_user user, to: gws_portal_path(site: site)

        within ".main-navi" do
          expect(page).to have_no_link(site.menu_memo_effective_label)
        end
        expect(page).to have_no_css(".gws-memo-message")
      end
    end
  end
end
