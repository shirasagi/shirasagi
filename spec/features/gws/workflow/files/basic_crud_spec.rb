require 'spec_helper'

describe "gws_workflow_files", type: :feature, dbscope: :example, tmpdir: true do
  context "basic crud", js: true do
    let(:site) { gws_site }
    let(:user) { gws_user }
    let(:index_path) { gws_workflow_files_path site }
    let!(:file) { tmp_ss_file(contents: '0123456789', user: user) }
    let(:item_name) { unique_id }
    let(:item_text) { unique_id }
    let(:item_name2) { unique_id }
    let(:item_text2) { unique_id }

    before { login_gws_user }

    it do
      visit index_path

      #
      # Create
      #
      click_link "新規作成"
      within "form#item-form" do
        fill_in "item[name]", with: item_name
        fill_in "item[text]", with: item_text

        click_on "アップロード"
      end

      within "article.file-view" do
        find("a.thumb").click
      end

      within "form#item-form" do
        click_on "保存"
      end

      expect(page).to have_css("div.addon-body dd", text: item_name)

      expect(Gws::Workflow::File.site(site).count).to eq 1
      item = Gws::Workflow::File.site(site).first
      expect(item.name).to eq item_name
      expect(item.text).to eq item_text
      expect(item.files.count).to eq 1
      expect(item.files.first.id).to eq file.id

      #
      # Update
      #
      click_on "編集する"
      within "form#item-form" do
        fill_in "item[name]", with: item_name2
        fill_in "item[text]", with: item_text2
        click_on "公開保存"
      end

      expect(page).to have_css("div.addon-body dd", text: item_name2)

      expect(Gws::Workflow::File.site(site).count).to eq 1
      item = Gws::Workflow::File.site(site).first
      expect(item.name).to eq item_name2
      expect(item.text).to eq item_text2
      expect(item.files.count).to eq 1
      expect(item.files.first.id).to eq file.id

      #
      # Delete
      #
      click_on "削除する"
      within "form" do
        click_on "削除"
      end
      expect(Gws::Workflow::File.site(site).count).to eq 0
    end
  end
end
