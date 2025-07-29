require 'spec_helper'

describe "cms_page_pages", type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:site) { cms_site }
  let(:permissions) { cms_role.permissions }
  let!(:role) { create :cms_role, name: "role", permissions: permissions }
  let!(:user) do
    create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", group_ids: [cms_group.id], cms_role_ids: [role.id])
  end

  context "delete all" do
    let!(:page1) { create(:cms_page) }
    let(:index_path) { cms_pages_path(site) }

    it do
      login_user(user)

      visit index_path
      wait_for_turbo_frame "#cms-nodes-tree-frame"

      within ".list-head" do
        wait_for_event_fired("ss:checked-all-list-items") { find('input[type="checkbox"]').set(true) }
        click_button I18n.t("ss.links.delete")
      end

      wait_for_js_ready
      click_button I18n.t("ss.buttons.delete")
      wait_for_notice I18n.t("ss.notice.deleted")
      wait_for_turbo_frame "#cms-nodes-tree-frame"

      expect(current_path).to eq index_path
    end

    context "without delete" do
      let(:permissions) { cms_role.permissions.reject { |item| item =~ /delete_/ } }

      it do
        login_user(user)

        visit index_path
        wait_for_turbo_frame "#cms-nodes-tree-frame"

        within ".list-head" do
          expect(page).to have_no_css(".destroy-all", text: I18n.t("ss.links.delete"))
        end
      end
    end
  end
end
