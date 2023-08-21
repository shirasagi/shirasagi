require 'spec_helper'

describe "uploader_files", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :uploader_node_file, name: "uploader" }
  let(:index_path) { uploader_files_path site.id, node }

  context "crumbs" do
    before { login_cms_user }
    let(:node1) { "abc" }
    let(:node2) { "def" }
    let(:node3) { "ghi" }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      click_link I18n.t('uploader.links.new_directory')
      fill_in "item[directory]", with: node1
      click_button I18n.t("ss.buttons.save")
      click_link node1

      click_link I18n.t('uploader.links.new_directory')
      fill_in "item[directory]", with: node2
      click_button I18n.t("ss.buttons.save")
      click_link node2

      click_link I18n.t('uploader.links.new_directory')
      fill_in "item[directory]", with: node3
      click_button I18n.t("ss.buttons.save")
      click_link node3

      click_link I18n.t('ss.links.upload')
      within "form" do
        attach_file "item[files][]", Rails.root.join("spec", "fixtures", "ss", "logo.png").to_s
        click_button I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#menu a", text: I18n.t("uploader.links.new_directory"))
      expect(page).to have_css("#menu a", text: I18n.t("ss.links.upload"))

      expect(page).to have_css(".list-item a", text: "logo.png")

      expect(page).to have_css("#crumbs li:nth-child(1) a", text: site.name)
      expect(page).to have_css("#crumbs li:nth-child(2) a", text: node.name)
      expect(page).to have_css("#crumbs li:nth-child(3) a", text: node1)
      expect(page).to have_css("#crumbs li:nth-child(4) a", text: node2)
      expect(page).to have_css("#crumbs li:nth-child(5) a", text: node3)

      within "#crumbs" do
        click_link node3
      end

      expect(page).to have_css("#menu a", text: I18n.t("uploader.links.new_directory"))
      expect(page).to have_css("#menu a", text: I18n.t("ss.links.upload"))

      expect(page).to have_css(".list-item a", text: "logo.png")

      expect(page).to have_css("#crumbs li:nth-child(1) a", text: site.name)
      expect(page).to have_css("#crumbs li:nth-child(2) a", text: node.name)
      expect(page).to have_css("#crumbs li:nth-child(3) a", text: node1)
      expect(page).to have_css("#crumbs li:nth-child(4) a", text: node2)
      expect(page).to have_css("#crumbs li:nth-child(5) a", text: node3)

      within "#crumbs" do
        click_link node2
      end

      expect(page).to have_css("#menu a", text: I18n.t("uploader.links.new_directory"))
      expect(page).to have_css("#menu a", text: I18n.t("ss.links.upload"))

      expect(page).to have_css(".list-item a", text: node3)
      expect(page).to have_no_css(".list-item a", text: "logo.png")

      expect(page).to have_css("#crumbs li:nth-child(1) a", text: site.name)
      expect(page).to have_css("#crumbs li:nth-child(2) a", text: node.name)
      expect(page).to have_css("#crumbs li:nth-child(3) a", text: node1)
      expect(page).to have_css("#crumbs li:nth-child(4) a", text: node2)
      expect(page).to have_no_css("#crumbs li:nth-child(5) a", text: node3)

      within "#crumbs" do
        click_link node1
      end

      expect(page).to have_css("#menu a", text: I18n.t("uploader.links.new_directory"))
      expect(page).to have_css("#menu a", text: I18n.t("ss.links.upload"))

      expect(page).to have_css(".list-item a", text: node2)
      expect(page).to have_no_css(".list-item a", text: "logo.png")

      expect(page).to have_css("#crumbs li:nth-child(1) a", text: site.name)
      expect(page).to have_css("#crumbs li:nth-child(2) a", text: node.name)
      expect(page).to have_css("#crumbs li:nth-child(3) a", text: node1)
      expect(page).to have_no_css("#crumbs li:nth-child(4) a", text: node2)
      expect(page).to have_no_css("#crumbs li:nth-child(5) a", text: node3)

      within "#crumbs" do
        click_link node.name
      end

      expect(page).to have_css("#menu a", text: I18n.t("uploader.links.new_directory"))
      expect(page).to have_css("#menu a", text: I18n.t("ss.links.upload"))

      expect(page).to have_css(".list-item a", text: node1)
      expect(page).to have_no_css(".list-item a", text: "logo.png")

      expect(page).to have_css("#crumbs li:nth-child(1) a", text: site.name)
      expect(page).to have_css("#crumbs li:nth-child(2) a", text: node.name)
      expect(page).to have_no_css("#crumbs li:nth-child(3) a", text: node1)
      expect(page).to have_no_css("#crumbs li:nth-child(4) a", text: node2)
      expect(page).to have_no_css("#crumbs li:nth-child(5) a", text: node3)
    end
  end
end
