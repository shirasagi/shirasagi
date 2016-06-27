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

    it "#edit" do
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

      click_link "logo.png"
      expect(status_code).to eq 200

      click_link "編集する"
      expect(status_code).to eq 200

      within "form" do
        fill_in "item[filename]", with: "#{node.filename}/replace.png"
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "webapi", "replace.png").to_s
        click_button "保存"
      end
      expect(status_code).to eq 200

      click_link "一覧へ戻る"

      expect(page).to have_css("a.file", text: "replace.png")
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

    it "#index with keyword" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

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

      click_link "新規フォルダー"
      within "form" do
        fill_in "item[directory]", with: "logos"
        click_button "保存"
      end

      files = page.all("a.file,a.dir").map(&:text)
      expect(files.index("logos")).to be_truthy
      expect(files.index("logo.png")).to be_truthy
      expect(files.index("replace.png")).to be_truthy

      within "form" do
        fill_in "s[keyword]", with: "logo"
        click_button "検索"
      end
      expect(status_code).to eq 200

      files = page.all("a.file,a.dir").map(&:text)
      expect(files.index("logos")).to be_truthy
      expect(files.index("logo.png")).to be_truthy
      expect(files.index("replace.png")).to be_falsey
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

  context "under subfolder" do
    let(:node_root) { create :cms_node_node, name: "parent" }
    let(:node) { create :uploader_node_file, cur_node: node_root, name: "uploader" }
    let(:index_path) { uploader_files_path site.id, node }

    before { login_cms_user }

    it do
      visit index_path

      #
      # examine file crud
      #
      click_link "アップロード"
      within "form" do
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s
        click_button "保存"
      end
      expect(page).to have_css(".list-item a", text: "logo.png")

      click_link "logo.png"
      expect(page).to have_css(".see dd", text: "#{node.filename}/logo.png")
      expect(page).to have_css(".see dd img")

      click_link "編集する"
      expect(page).to have_css("form")
      fill_in "item[filename]", with: "#{node.filename}/replace.png"
      click_button "保存"

      click_link "詳細へ戻る"
      expect(page).to have_css(".see dd", text: "#{node.filename}/replace.png")
      expect(page).to have_css(".see dd img")

      click_link "削除する"
      click_button "削除"
      expect(page).not_to have_css(".list-item")

      #
      # examine directory crud
      #
      click_link "新規フォルダー"
      fill_in "item[directory]", with: "foo"
      click_button "保存"

      expect(page).to have_css(".list-item a", text: "foo")
      click_link "foo"

      expect(page).to have_css(".list-item a.up", text: "上の階層へ")
      click_link "上の階層へ"

      click_link "詳細を見る"
      expect(page).to have_css(".see dd", text: "#{node.filename}/foo")
      click_link "編集する"
      fill_in "item[filename]", with: "#{node.filename}/bar"
      click_button "保存"
      click_link "詳細へ戻る"
      expect(page).to have_css(".see dd", text: "#{node.filename}/bar")

      click_link "削除する"
      click_button "削除"
      expect(page).not_to have_css(".list-item")
    end
  end
end
