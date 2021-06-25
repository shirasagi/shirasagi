require 'spec_helper'

describe "key_visual_images", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create_once :key_visual_node_image, name: "key_visual" }
  let(:index_path) { key_visual_images_path site.id, node }

  context "with auth" do
    let!(:file) do
      tmp_ss_file(
        Cms::TempFile, user: cms_user, site: site, node: node, contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end
    let(:name) { "sample" }
    let(:name2) { "modify" }

    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path

      SS.config.replace_value_at(:env, :max_filesize_ext, {})

      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[link_url]", with: "http://example.jp"
        first(".btn-file-upload").click
      end
      wait_for_cbox do
        expect(page).to have_css(".file-view", text: file.name)
        click_on file.name
      end
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit index_path
      click_on name
      expect(page).to have_css("#addon-basic", text: name)

      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      visit index_path
      click_on name2
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")
    end
  end
end
