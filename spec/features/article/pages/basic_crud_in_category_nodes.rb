require 'spec_helper'

describe "article_pages", dbscope: :example do
  let(:site) { cms_site }
  let(:item) { create(:article_page, cur_node: node) }
  let(:index_path) { article_pages_path site.id, node }
  let(:new_path) { new_article_page_path site.id, node }
  let(:show_path) { article_page_path site.id, node, item }
  let(:edit_path) { edit_article_page_path site.id, node, item }
  let(:delete_path) { delete_article_page_path site.id, node, item }
  let(:move_path) { move_article_page_path site.id, node, item }
  let(:copy_path) { copy_article_page_path site.id, node, item }

  context "basic crud in category_node_node" do
    let(:node) { create_once :category_node_node, filename: "category", name: "category" }
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
        fill_in "destination", with: "category/destination"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq move_path
      expect(page).to have_css("form#item-form h2", text: "category/destination.html")

      within "form" do
        fill_in "destination", with: "category/sample"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq move_path
      expect(page).to have_css("form#item-form h2", text: "category/sample.html")
    end

    it "#copy" do
      visit copy_path
      within "form" do
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
      expect(page).to have_css("a", text: "[複製] #{item.name}")
      expect(page).to have_css(".state", text: "非公開")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(current_path).to eq index_path
    end
  end

  context "basic crud in category_node_page" do
    let(:node) { create_once :category_node_page, filename: "category", name: "category" }
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
        fill_in "destination", with: "category/destination"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq move_path
      expect(page).to have_css("form#item-form h2", text: "category/destination.html")

      within "form" do
        fill_in "destination", with: "category/sample"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq move_path
      expect(page).to have_css("form#item-form h2", text: "category/sample.html")
    end

    it "#copy" do
      visit copy_path
      within "form" do
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
      expect(page).to have_css("a", text: "[複製] #{item.name}")
      expect(page).to have_css(".state", text: "非公開")
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
