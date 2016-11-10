require 'spec_helper'

describe "event_pages" do
  subject(:site) { cms_site }
  subject(:node) { create_once :event_node_page, filename: "docs", name: "event" }
  subject(:item) { Event::Page.last }
  subject(:index_path) { event_pages_path site.id, node }
  subject(:new_path) { new_event_page_path site.id, node }
  subject(:show_path) { event_page_path site.id, node, item }
  subject(:edit_path) { edit_event_page_path site.id, node, item }
  subject(:delete_path) { delete_event_page_path site.id, node, item }
  subject(:move_path) { move_event_page_path site.id, node, item }
  subject(:copy_path) { copy_event_page_path site.id, node, item }
  subject(:contain_links_path) { contain_links_event_page_path site.id, node, item }

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
        fill_in "item[basename]", with: "sample"
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

    it "#move" do
      visit move_path
      within "form" do
        fill_in "destination", with: "docs/destination"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq move_path
      expect(page).to have_css("form#item-form h2", text: "docs/destination.html")

      within "form" do
        fill_in "destination", with: "docs/sample"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq move_path
      expect(page).to have_css("form#item-form h2", text: "docs/sample.html")
    end

    it "#copy" do
      visit copy_path
      within "form" do
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
      expect(page).to have_css("a", text: "[複製] modify")
      expect(page).to have_css(".state", text: "非公開")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(current_path).to eq index_path
    end

    it "#contain_links" do
      visit delete_path
      click_link "このページへのリンクを確認する。"

      expect(current_path).to eq contain_links_path
    end
  end
end
