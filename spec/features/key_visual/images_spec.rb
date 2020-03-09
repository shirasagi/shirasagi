require 'spec_helper'

describe "key_visual_images", type: :feature, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :key_visual_node_image, name: "key_visual" }
  let(:item) { KeyVisual::Image.last }
  let(:index_path) { key_visual_images_path site.id, node }
  let(:new_path) { new_key_visual_image_path site.id, node }
  let(:show_path) { key_visual_image_path site.id, node, item }
  let(:edit_path) { edit_key_visual_image_path site.id, node, item }
  let(:delete_path) { delete_key_visual_image_path site.id, node, item }

  context "with auth" do
    let!(:file) do
      tmp_ss_file(
        Cms::TempFile, user: cms_user, site: site, node: node, contents: "#{Rails.root}/spec/fixtures/ss/logo.png"
      )
    end

    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      SS.config.replace_value_at(:env, :max_filesize_ext, {})

      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[link_url]", with: "http://example.jp"
        first(".btn-file-upload").click
      end
      wait_for_cbox do
        # click_on file.name
        expect(page).to have_css(".file-view", text: file.name)
        first("a[data-id='#{file.id}']").click
      end
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")
    end
  end
end
