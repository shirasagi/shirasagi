require 'spec_helper'

describe "cms_search_contents_files", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:name1) { "#{unique_id}.png" }
  let!(:name2) { "#{unique_id}.png" }
  let!(:file1) { tmp_ss_file contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: cms_user, basename: name1 }
  let!(:file2) { tmp_ss_file contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: cms_user, basename: name2 }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
  let!(:column1) do
    create(:cms_column_file_upload, cur_site: site, cur_form: form, order: 1, file_type: "image")
  end
  let!(:column2) do
    create(:cms_column_free, cur_site: site, cur_form: form, order: 2)
  end
  let!(:node) { create :article_node_page, cur_site: site, cur_user: cms_user }
  let!(:item1) { create :article_page, cur_site: site, cur_user: cms_user, cur_node: node }

  before do
    node.st_form_ids = [ form.id ]
    node.save!

    item1.form = form
    item1.column_values = [
      column1.value_type.new(column: column1, file_id: file1.id, file_label: file1.humanized_name),
      column2.value_type.new(column: column2, value: unique_id * 2, file_ids: [ file2.id ])
    ]
    item1.save!

    login_cms_user
  end

  context "with article/page with static form" do
    describe "index" do
      it do
        visit cms_search_contents_files_path(site: site)
        expect(page).to have_css(".file-view", text: name1)
        expect(page).to have_css(".file-view", text: name2)
        expect(page).to have_css(".file-view", text: item1.name)
        image_element_info(first(".file-view img[alt='#{file1.name}']")).tap do |info|
          expect(info[:width]).to eq 90
          expect(info[:height]).to eq 90
        end
        image_element_info(first(".file-view img[alt='#{file2.name}']")).tap do |info|
          expect(info[:width]).to eq 90
          expect(info[:height]).to eq 90
        end
      end
    end

    describe "search" do
      it do
        visit cms_search_contents_files_path(site: site)
        within "form.search" do
          fill_in "s[keyword]", with: name1
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".file-view", text: name1)
        expect(page).to have_no_css(".file-view", text: name2)
        expect(page).to have_css(".file-view", text: item1.name)
        image_element_info(first(".file-view img[alt='#{file1.name}']")).tap do |info|
          expect(info[:width]).to eq 90
          expect(info[:height]).to eq 90
        end

        within "form.search" do
          fill_in "s[keyword]", with: name2
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_no_css(".file-view", text: name1)
        expect(page).to have_css(".file-view", text: name2)
        expect(page).to have_css(".file-view", text: item1.name)
        image_element_info(first(".file-view img[alt='#{file2.name}']")).tap do |info|
          expect(info[:width]).to eq 90
          expect(info[:height]).to eq 90
        end

        # by page's name
        within "form.search" do
          fill_in "s[keyword]", with: item1.name
          click_on I18n.t("ss.buttons.search")
        end
        expect(page).to have_css(".file-view", text: name1)
        expect(page).to have_css(".file-view", text: name2)
        expect(page).to have_css(".file-view", text: item1.name)
        image_element_info(first(".file-view img[alt='#{file1.name}']")).tap do |info|
          expect(info[:width]).to eq 90
          expect(info[:height]).to eq 90
        end
        image_element_info(first(".file-view img[alt='#{file2.name}']")).tap do |info|
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
        within first(".file-view") do
          # click_on item1.name
          js_click find(:link_or_button, item1.name)
        end

        switch_to_window(windows.last)
        wait_for_document_loading
        expect(current_path).to eq item1.private_show_path
        expect(current_path).to eq article_page_path(site: site, cid: node, id: item1)
      end
    end
  end
end
