require 'spec_helper'

describe "uploader_files", dbscope: :example, type: :feature do
  let(:site) { cms_site }
  let(:node) { create_once :uploader_node_file, name: "uploader" }
  let(:index_path) { uploader_files_path site.id, node }

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

    it "upload file" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      click_link "アップロード"

      within "form" do
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s
        click_button "保存"
      end

      expect(page).to have_css("div.info")
      within "div.info" do
        expect(page).to have_css("a.file")
      end
    end

    it "create directory" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      click_link "新規フォルダー"

      within "form" do
        fill_in "item[directory]", with: unique_id
        click_button "保存"
      end

      expect(page).to have_css("div.info")
      within "div.info" do
        expect(page).to have_css("a.dir")
      end
    end
  end

  describe "ss-850", js: true do
    # see: https://github.com/shirasagi/shirasagi/issues/850
    before { login_cms_user }

    it do
      visit index_path

      # upload multiple files

      click_link "アップロード"
      within "form" do
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s
        click_button "保存"
      end

      click_link "アップロード"
      within "form" do
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "webapi", "replace.png").to_s
        click_button "保存"
      end

      expect(page).to have_css("div.info a.file", count: 2)

      # check one file

      find(:css, "input[value='logo.png']").set(true)
      within "div.list-head-action" do
        click_button "削除する"
      end

      page.accept_alert

      within "div.info" do
        expect(page).to have_css("a.file")
      end
    end
  end
end
