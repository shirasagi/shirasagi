require 'spec_helper'

describe "content_quota", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node1) { create :article_node_page, shortcut: "show", group_ids: user.group_ids }
  let!(:node2) { create :article_node_page, shortcut: "hide", group_ids: user.group_ids }
  let!(:node3) { create :article_node_page, shortcut: "show", group_ids: [] }

  describe "basic crud" do
    before { login_cms_user }

    it do
      visit cms_contents_path(site: site)
      within "#navi" do
        wait_for_cbox_opened do
          click_on I18n.t("cms.content_quota_navi")
        end
      end
      within_cbox do
        expect(page).to have_text node1.name
        expect(page).to have_text node1.filename

        expect(page).to have_no_text node2.name
        expect(page).to have_no_text node2.filename

        expect(page).to have_no_text node3.name
        expect(page).to have_no_text node3.filename
      end
    end
  end
end
