require 'spec_helper'

describe "article_pages", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:item) { create(:article_page, cur_node: node) }
  let(:show_path) { article_page_path site.id, node, item }
  let(:edit_path) { edit_article_page_path site.id, node, item }
  let(:lock_path) { lock_article_page_path site.id, node, item }

  feature "lock and unlock" do
    given(:group) { cms_group }
    given(:user1) { create(:cms_test_user, group: group) }

    background do
      item.acquire_lock(user: user1)
    end

    background { login_cms_user }

    scenario "locked by other then unlock and edit forcibly" do
      expect(item.lock_owner_id).not_to eq cms_user.id

      visit show_path
      expect(status_code).to eq 200

      within "div#addon-cms-agents-addons-edit_lock" do
        expect(page).to have_content(I18n.t("errors.messages.locked", user: item.lock_owner.long_name))
      end

      click_link "編集する"
      expect(status_code).to eq 200
      expect(current_path).to eq lock_path

      click_button I18n.t("views.button.unlock_and_edit_forcibly")
      expect(status_code).to eq 200
      expect(current_path).to eq edit_path

      item.reload
      expect(item.lock_owner_id).to eq cms_user.id
    end
  end
end
