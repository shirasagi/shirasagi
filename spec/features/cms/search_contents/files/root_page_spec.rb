require 'spec_helper'

describe "cms_search_contents_files", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:name) { "#{unique_id}.png" }
  let!(:file) { tmp_ss_file contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: cms_user, basename: name }
  let!(:item1) { create :cms_page, cur_site: site, cur_user: cms_user, file_ids: [ file.id ] }

  before { login_cms_user }

  context "with root cms/page" do
    describe "index" do
      it do
        visit cms_search_contents_files_path(site: site)
        expect(page).to have_css(".file-view", text: name)
        expect(page).to have_css(".file-view", text: item1.name)
        image_element_info(first(".file-view img[alt='#{file.name}']")).tap do |info|
          expect(info[:width]).to eq 90
          expect(info[:height]).to eq 90
        end
      end
    end

    describe "search" do
      it do
        # by file's name
        visit cms_search_contents_files_path(site: site)
        within "form.search" do
          fill_in "s[keyword]", with: name
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".file-view", text: name)
        expect(page).to have_css(".file-view", text: item1.name)
        image_element_info(first(".file-view img[alt='#{file.name}']")).tap do |info|
          expect(info[:width]).to eq 90
          expect(info[:height]).to eq 90
        end

        # by page's name
        within "form.search" do
          fill_in "s[keyword]", with: item1.name
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".file-view", text: name)
        expect(page).to have_css(".file-view", text: item1.name)
        image_element_info(first(".file-view img[alt='#{file.name}']")).tap do |info|
          expect(info[:width]).to eq 90
          expect(info[:height]).to eq 90
        end

        within "form.search" do
          fill_in "s[keyword]", with: unique_id
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".file-view", count: 0)
        expect(page).to have_css(".search-contents-form", count: 1)
      end
    end

    describe "transfer to appropriate path after click on file" do
      it do
        visit cms_search_contents_files_path(site: site)
        # click_on item1.name
        js_click find(:link_or_button, item1.name)

        switch_to_window(windows.last)
        wait_for_document_loading
        expect(current_path).to eq item1.private_show_path
        expect(current_path).to eq cms_page_path(site: site, id: item1)
      end
    end
  end
end
