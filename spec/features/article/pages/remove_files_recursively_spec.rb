require 'spec_helper'

describe "article_pages remove_files_recursively", dbscope: :example do
  let(:site) { cms_site }
  let(:node) {
    create_once :article_node_page, filename: "docs", name: "article", state: "public", for_member_state: "disabled"
  }
  let(:item) { create(:article_page, cur_node: node) }

  let(:edit_path) { edit_node_conf_path site.id, node }
  let(:delete_path) { delete_node_conf_path site.id, node }

  context "not changed", js: true do
    before { login_cms_user }

    it "#edit" do
      expect(::File.exists?(item.path)).to be true

      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button "保存"
      end

      expect(::File.exists?(item.path)).to be true
    end
  end

  context "state changed", js: true do
    before { login_cms_user }

    it "#edit" do
      expect(::File.exists?(item.path)).to be true

      visit edit_path

      find("#addon-cms-agents-addons-release .toggle-head").click
      select "非公開", from: "item_state"

      within "form#item-form" do
        click_button "保存"
      end

      expect(::File.exists?(item.path)).to be false
    end
  end

  context "route changed", js: true do
    before { login_cms_user }

    it "#edit" do
      expect(::File.exists?(item.path)).to be true

      visit edit_path

      within "form#item-form" do
        click_link "変更する"
      end

      wait_for_cbox

      click_link "広告バナー"

      expect(page).to have_content '広告管理/広告バナー'

      within "form#item-form" do
        click_button "保存"
      end

      expect(::File.exists?(item.path)).to be false
    end
  end

  context "for_member_state changed", js: true do
    before { login_cms_user }

    it "#edit" do
      expect(::File.exists?(item.path)).to be true

      visit edit_path

      find("#addon-cms-agents-addons-for_member_node .toggle-head").click
      select "有効", from: "item_for_member_state"

      within "form#item-form" do
        click_button "保存"
      end

      expect(::File.exists?(item.path)).to be false
    end
  end
end
