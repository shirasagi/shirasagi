require 'spec_helper'

describe "uploader_files", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :uploader_node_file, name: "uploader" }
  let(:index_path) { uploader_files_path site.id, node }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "upload file" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      click_link I18n.t('ss.links.upload')

      within "form" do
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s
        click_button I18n.t("ss.buttons.save")
      end

      expect(page).to have_css("div.info")
      within "div.info" do
        expect(page).to have_css("a.file")
      end
    end

    it "#edit" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      click_link I18n.t('ss.links.upload')

      within "form" do
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s
        click_button I18n.t("ss.buttons.save")
      end

      expect(page).to have_css("div.info")
      within "div.info" do
        expect(page).to have_css("a.file")
      end

      click_link "logo.png"
      expect(status_code).to eq 200

      click_link I18n.t('ss.links.edit')
      expect(status_code).to eq 200

      within "form" do
        fill_in "item[filename]", with: "#{node.filename}/replace.png"
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "webapi", "replace.png").to_s
        click_button I18n.t("ss.buttons.save")
      end
      expect(status_code).to eq 200

      click_link I18n.t('ss.links.back_to_index')

      expect(page).to have_css("a.file", text: "replace.png")
    end

    it "create directory" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      click_link I18n.t('uploader.links.new_directory')

      within "form" do
        fill_in "item[directory]", with: unique_id
        click_button I18n.t("ss.buttons.save")
      end

      expect(page).to have_css("div.info")
      within "div.info" do
        expect(page).to have_css("a.dir")
      end
    end

    it "#index with keyword" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      click_link I18n.t('ss.links.upload')
      within "form" do
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s
        click_button I18n.t("ss.buttons.save")
      end

      click_link I18n.t('ss.links.upload')
      within "form" do
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "webapi", "replace.png").to_s
        click_button I18n.t("ss.buttons.save")
      end

      click_link I18n.t('uploader.links.new_directory')
      within "form" do
        fill_in "item[directory]", with: "logos"
        click_button I18n.t("ss.buttons.save")
      end

      files = page.all("a.file,a.dir").map(&:text)
      expect(files.index("logos")).to be_truthy
      expect(files.index("logo.png")).to be_truthy
      expect(files.index("replace.png")).to be_truthy

      within "form" do
        fill_in "s[keyword]", with: "logo"
        click_button I18n.t('ss.buttons.search')
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

      click_link I18n.t('ss.links.upload')
      within "form" do
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s
        click_button I18n.t("ss.buttons.save")
      end

      click_link I18n.t('ss.links.upload')
      within "form" do
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "webapi", "replace.png").to_s
        click_button I18n.t("ss.buttons.save")
      end

      expect(page).to have_css("div.info a.file", count: 2)

      # check one file

      find(:css, "input[value='logo.png']").set(true)
      page.accept_alert do
        within "div.list-head-action" do
          click_button I18n.t('ss.links.delete')
        end
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
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
      click_link I18n.t('ss.links.upload')
      within "form" do
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s
        click_button I18n.t("ss.buttons.save")
      end
      expect(page).to have_css(".list-item a", text: "logo.png")

      click_link "logo.png"
      expect(page).to have_css(".see dd", text: "#{node.filename}/logo.png")
      expect(page).to have_css(".see dd img")

      click_link I18n.t('ss.links.edit')
      expect(page).to have_css("form")
      fill_in "item[filename]", with: "#{node.filename}/replace.png"
      click_button I18n.t("ss.buttons.save")

      click_link I18n.t('ss.links.back_to_show')
      expect(page).to have_css(".see dd", text: "#{node.filename}/replace.png")
      expect(page).to have_css(".see dd img")

      click_link I18n.t('ss.links.delete')
      click_button I18n.t("ss.buttons.delete")
      expect(page).to have_no_css(".list-item")

      #
      # examine directory crud
      #
      click_link I18n.t('uploader.links.new_directory')
      fill_in "item[directory]", with: "foo"
      click_button I18n.t("ss.buttons.save")

      expect(page).to have_css(".list-item a", text: "foo")
      click_link "foo"

      expect(page).to have_css(".list-item a.up", text: I18n.t("ss.links.parent_directory"))
      click_link I18n.t("ss.links.parent_directory")

      click_link I18n.t("ss.links.show")
      expect(page).to have_css(".see dd", text: "#{node.filename}/foo")
      click_link I18n.t('ss.links.edit')
      fill_in "item[filename]", with: "#{node.filename}/bar"
      click_button I18n.t("ss.buttons.save")
      click_link I18n.t('ss.links.back_to_show')
      expect(page).to have_css(".see dd", text: "#{node.filename}/bar")

      click_link I18n.t('ss.links.delete')
      click_button I18n.t("ss.buttons.delete")
      expect(page).to have_no_css(".list-item")
    end
  end

  context "with scss" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "upload file" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      click_link I18n.t('ss.links.upload')

      within "form" do
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "uploader", "style.scss").to_s
        click_button I18n.t("ss.buttons.save")
      end

      expect(page).to have_css("a.file", text: "style.scss")
      expect(page).to have_css("a.file", text: "style.css")
    end

    it "overwrite file" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      click_link I18n.t('ss.links.upload')

      within "form" do
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "uploader", "style.scss").to_s
        click_button I18n.t("ss.buttons.save")
      end

      expect(page).to have_css("a.file", text: "style.scss")
      expect(page).to have_css("a.file", text: "style.css")

      click_link "style.scss"
      expect(status_code).to eq 200

      click_link I18n.t('ss.links.edit')
      expect(status_code).to eq 200

      within "form" do
        fill_in "item[filename]", with: "#{node.filename}/replace.scss"
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "uploader", "replace.scss").to_s
        click_button I18n.t("ss.buttons.save")
      end
      expect(status_code).to eq 200

      click_link I18n.t('ss.links.back_to_index')

      expect(page).to have_css("a.file", text: "replace.scss")
      expect(page).to have_css("a.file", text: "replace.css")
      expect(page).to have_no_css("a.file", text: "style.scss")
      expect(page).to have_css("a.file", text: "style.css")
    end

    it '#edit' do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      click_link I18n.t('ss.links.upload')

      within "form" do
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "uploader", "style.scss").to_s
        click_button I18n.t("ss.buttons.save")
      end

      expect(page).to have_css("a.file", text: "style.scss")
      expect(page).to have_css("a.file", text: "style.css")

      click_link "style.scss"
      expect(status_code).to eq 200

      click_link I18n.t('ss.links.edit')
      expect(status_code).to eq 200

      within "form" do
        fill_in "item[filename]", with: "#{node.filename}/replace.scss"
        fill_in 'item[text]', with: 'html { height: 75%; }'
        click_button I18n.t("ss.buttons.save")
      end
      expect(status_code).to eq 200
      expect(page).to have_css('#item_text', text: 'html { height: 75%; }')

      click_link I18n.t('ss.links.back_to_index')

      expect(page).to have_css("a.file", text: "replace.scss")
      expect(page).to have_css("a.file", text: "replace.css")
      expect(page).to have_no_css("a.file", text: "style.scss")
      expect(page).to have_css("a.file", text: "style.css")
    end
  end

  context "with invalid filename" do
    let(:filename) { "/#{node.filename}/..%2Frobots.txt" }

    before do
      ::FileUtils.touch("#{site.path}/robots.txt")
      login_cms_user
    end

    it "#show" do
      visit uploader_file_path(site: site, cid: node, filename: filename, do: "show")
      expect(status_code).to eq 404
    end
  end
end
