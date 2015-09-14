require 'spec_helper'

describe "board_posts", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :board_node_post, filename: "posts", name: "posts" }
  let(:item) { create(:board_post, node: node) }
  let(:index_path) { board_posts_path site.id, node }
  let(:new_path) { new_board_post_path site.id, node }
  let(:show_path) { board_post_path site.id, node, item }
  let(:edit_path) { edit_board_post_path site.id, node, item }
  let(:delete_path) { delete_board_post_path site.id, node, item }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[poster]", with: "sample"
        fill_in "item[text]", with: "sample"
        fill_in "item[delete_key]", with: "pass"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button "保存"
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(current_path).to eq index_path
    end
  end
end
