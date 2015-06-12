require 'spec_helper'

describe "rss_pages", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :rss_node_page, site: site }
  let(:index_path) { rss_pages_path site.host, node.id }
  let(:new_path) { new_rss_page_path site.host, node.id }
  let(:import_path) { import_rss_pages_path site.host, node.id }

  context "without login" do
    it do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq sns_login_path
    end
  end

  context "without auth" do
    it do
      login_ss_user
      visit index_path
      expect(status_code).to eq 403
    end
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        fill_in "item[rss_link]", with: "http://example.jp/docs/1.html"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#import" do
      visit import_path
      expect(status_code).to eq 200
      expect(current_path).to eq import_path
      click_button I18n.t("rss.views.button.import")
    end

    context "with item" do
      let(:item) { create(:rss_page, site: site, node: node) }
      let(:show_path) { rss_page_path site.host, node.id, item }
      let(:edit_path) { edit_rss_page_path site.host, node.id, item }
      let(:delete_path) { delete_rss_page_path site.host, node.id, item }

      it "#index" do
        item.id
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        within "table.index" do
          expect(page).to have_content(item.name)
        end
      end

      it "#show" do
        visit show_path
        expect(status_code).to eq 200
        expect(current_path).to eq show_path
      end

      it "#edit" do
        visit edit_path
        within "form#item-form" do
          fill_in "item[name]", with: "modify"
          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq sns_login_path
        expect(page).not_to have_css("form#item-form")
      end

      it "#delete" do
        visit delete_path
        within "form" do
          click_button "削除"
        end
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end
    end
  end
end
