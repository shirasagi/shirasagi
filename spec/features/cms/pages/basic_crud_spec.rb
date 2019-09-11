require 'spec_helper'

describe "cms/pages", type: :feature, dbscope: :example do
  subject(:site) { cms_site }
  subject(:index_path) { cms_pages_path site.id }

  describe "basic crud" do
    before { login_cms_user }

    it do
      #
      # new
      #
      visit new_cms_page_path(site.id)
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_button I18n.t("ss.buttons.save")
      end
      expect(status_code).to eq 200

      item = Cms::Page.last
      expect(item.name).to eq "sample"
      expect(item.filename).to eq "sample.html"

      #
      # show
      #
      visit cms_page_path(site.id, item)
      expect(status_code).to eq 200
      expect(page).to have_content("sample.html")

      #
      # edit
      #
      visit edit_cms_page_path(site.id, item)
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t("ss.buttons.save")
      end
      expect(status_code).to eq 200

      item.reload
      expect(item.name).to eq "modify"
      expect(item.filename).to eq "sample.html"

      #
      # move
      #
      visit move_cms_page_path(site.id, item)
      within "form" do
        fill_in "destination", with: "destination"
        click_button I18n.t("ss.buttons.save")
      end
      expect(status_code).to eq 200
      expect(page).to have_css("form#item-form h2", text: "destination.html")

      item.reload
      expect(item.name).to eq "modify"
      expect(item.filename).to eq "destination.html"

      visit move_cms_page_path(site.id, item)
      within "form" do
        fill_in "destination", with: "sample"
        click_button I18n.t("ss.buttons.save")
      end
      expect(status_code).to eq 200
      expect(page).to have_css("form#item-form h2", text: "sample.html")

      item.reload
      expect(item.name).to eq "modify"
      expect(item.filename).to eq "sample.html"

      #
      # copy
      #
      visit copy_cms_page_path(site.id, item)
      within "form" do
        click_button I18n.t("ss.buttons.save")
      end
      expect(status_code).to eq 200
      expect(page).to have_css("a", text: "[複製] modify")
      expect(page).to have_css(".state", text: "非公開")

      expect(Cms::Page.count).to eq 2

      #
      # contains_urls
      #
      visit contains_urls_cms_page_path(site.id, item)
      expect(status_code).to eq 200

      #
      # delete
      #
      visit delete_cms_page_path(site.id, item)
      within "form" do
        click_button I18n.t("ss.buttons.delete")
      end
      expect(current_path).to eq index_path
    end
  end
end
